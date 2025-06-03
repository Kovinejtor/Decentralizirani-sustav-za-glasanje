<template>
  <div class="min-h-screen flex flex-col items-center pt-12 px-4 text-gray-100 space-y-8">
    <div class="w-full max-w-6xl bg-gray-900 rounded-lg p-8 shadow-lg flex flex-col items-center">
      <h1 class="text-4xl font-bold mb-8">Decentralizirano glasanje</h1>

      <div v-if="jeAdmin" class="flex flex-col items-center gap-4 mt-10">
        <div class="flex flex-wrap gap-4 justify-center items-center">
          <div class="flex flex-col mt-6">
            <input 
              v-model="noviKandidat" 
              :disabled="glasanjeAktivno"
              class="border border-gray-600 bg-gray-800 text-white px-3 py-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
              placeholder="Unesi ime kandidata" 
            />
            <div class="h-5 mt-1 text-center">
              <span v-if="greskaPoruka" class="text-red-500 text-sm">
                {{ greskaPoruka }}
              </span>
            </div>
          </div>

          <button 
            @click="dodajKandidata" 
            :disabled="glasanjeAktivno" 
            class="bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded disabled:opacity-50"
          >
            Dodaj kandidata
          </button>

          <button 
            @click="obrisiKandidate" 
            :disabled="kandidati.length === 0 || glasanjeAktivno" 
            class="bg-gray-600 hover:bg-gray-700 text-white px-4 py-2 rounded disabled:opacity-50"
          >
            Obriši sve kandidate
          </button>

          <button 
            @click="pokreniGlasanje" 
            :disabled="glasanjeAktivno || kandidati.length === 0" 
            class="bg-green-600 hover:bg-green-700 text-white px-4 py-2 rounded disabled:opacity-50"
          >
            Pokreni glasanje
          </button>

          <button 
            @click="zaustaviGlasanje" 
            :disabled="!glasanjeAktivno" 
            class="bg-red-500 hover:bg-red-600 text-white px-4 py-2 rounded disabled:opacity-50"
          >
            Zaustavi glasanje
          </button>
        </div>
      </div>
    </div>

    <div v-if="(jeAdmin || glasanjeAktivno)" class="w-full max-w-6xl bg-gray-900 rounded-lg p-8 shadow-lg">
      <div class="text-center text-xl font-semibold mb-6">
        <p>
          Kandidati:
          <span v-if="kandidati.length === 0" class="text-gray-400 italic">Nema kandidata</span>
        </p>
      </div>

      <div v-if="kandidati.length > 0" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-4 gap-6">
        <div 
          v-for="k in kandidati" 
          :key="k.id" 
          class="relative bg-gray-800 border border-gray-700 p-6 rounded-xl shadow-md flex flex-col items-center justify-between"
        >
          <div class="absolute top-2 right-2">
            <button 
              v-if="jeAdmin" 
              @click="obrisiKandidata(k.id)" 
              :disabled="glasanjeAktivno"
              class="text-gray-400 hover:text-red-500 disabled:opacity-30"
              title="Obriši kandidata"
            >
              ✕
            </button>
          </div>
          <div>
            <h2 class="text-xl font-semibold text-center">{{ k.ime }}</h2>
            <p class="text-center mt-2 text-gray-400">{{ k.brojGlasova }} glasova</p>
          </div>
          <button
            class="mt-6 bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded disabled:opacity-50"
            @click="glasaj(k.id)"
            :disabled="!glasanjeAktivno || jeGlasao"
          >
            Glasaj
          </button>
        </div>
      </div>
    </div>

    <div v-if="pobjednik" class="mt-16 text-center">
      <p class="text-3xl font-semibold text-green-400 flex items-center justify-center gap-4">
        🏆 Pobjednik: {{ pobjednik }}
        <button
          v-if="showDownloadButton"
          @click="downloadCSV"
          class="ml-4 bg-blue-600 hover:bg-blue-700 text-white px-4 py-2 rounded"
        >
          Preuzmi rezultate
        </button>
      </p>
    </div>
    <div v-if="jeGlasao" class="mt-8 text-center">
      <p class="text-xl font-semibold text-green-400">Hvala Vam na glasanju!</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted, onBeforeUnmount } from 'vue'
import { ethers } from 'ethers'
import { glasanjeAbi } from '../contracts/abi.js'
import contractMeta from '../contracts/contract-address.json'
import { watch } from 'vue'

const kandidati = ref([])
const noviKandidat = ref('')
const pobjednik = ref(null)
const jeAdmin = ref(false)
const glasanjeAktivno = ref(false)
const showDownloadButton = ref(false)
const savedResults = ref([])
const greskaPoruka = ref('')
const jeGlasao = ref(false)
const intervalId = ref(null)

const contractAddress = contractMeta.contractAddress
let contract

watch([glasanjeAktivno, kandidati], ([novoGlasanjeAktivno, novaListaKandidata], [prethodnoAktivno]) => {
  if (prethodnoAktivno === false && novoGlasanjeAktivno && novaListaKandidata.length > 0) {
    pobjednik.value = null
    savedResults.value = []
    showDownloadButton.value = false
  }
})

async function switchToLocalhostNetwork() {
  const targetChainId = '0x7a69'
  const currentChainId = await window.ethereum.request({ method: 'eth_chainId' })

  if (currentChainId !== targetChainId) {
    await window.ethereum.request({
      method: 'wallet_switchEthereumChain',
      params: [{ chainId: targetChainId }],
    })
  }
}

onMounted(async () => {
  await switchToLocalhostNetwork()

  const provider = new ethers.BrowserProvider(window.ethereum)
  const signer = await provider.getSigner()

  contract = new ethers.Contract(contractAddress, glasanjeAbi, signer)

  const userAddress = await signer.getAddress()
  const adminAddress = await contract.administrator()

  jeAdmin.value = userAddress.toLowerCase() === adminAddress.toLowerCase()

  await ucitajKandidate()
  await ucitajStanje()
  
  intervalId.value = setInterval(async () => {
    const aktivnoPromise = contract.glasanjeAktivno()
    const kandidatiPromise = ucitajKandidate()

    const stanje = await aktivnoPromise
    if (glasanjeAktivno.value && !stanje) {
      pobjednik.value = await contract.dohvatiZadnjegPobjednika()

      const kandidatiSaServera = await contract.dohvatiSveKandidate()
      const lista = kandidatiSaServera.map(k => ({
        id: Number(k.id),
        ime: k.ime,
        brojGlasova: Number(k.brojGlasova)
      }))
      lista.sort((a, b) => b.brojGlasova - a.brojGlasova)
      savedResults.value = lista
      showDownloadButton.value = true

      kandidati.value = []  
    }
    glasanjeAktivno.value = stanje

    await kandidatiPromise
    await provjeriJeLiGlasao()
  }, 1000)
})

onBeforeUnmount(() => {
  if (intervalId.value) {
    clearInterval(intervalId.value)
  }
})

async function ucitajKandidate() {
  const broj = await contract.brojKandidata()
  const lista = []
  for (let i = 0; i < broj; i++) {
    const k = await contract.kandidati(i)
    if (k[1] !== '') {
      lista.push({ id: Number(k[0]), ime: k[1], brojGlasova: Number(k[2]) })
    }
  }
  kandidati.value = lista
}


async function provjeriJeLiGlasao() {
  try {
    if (jeAdmin.value) return; 
    const userAddress = await window.ethereum.request({ method: 'eth_requestAccounts' }).then(accounts => accounts[0]);
    const birac = await contract.biraci(userAddress);
    jeGlasao.value = birac.glasao;
  } catch (error) {
    console.error('Greška prilikom provjere da li je korisnik glasao:', error);
  }
}

async function ucitajStanje() {
  const trenutnoAktivno = await contract.glasanjeAktivno()

  glasanjeAktivno.value = trenutnoAktivno
  await provjeriJeLiGlasao()
}


async function pokreniGlasanje() {
  const tx = await contract.pokreniGlasanje()
  await tx.wait()

  pobjednik.value = null
  savedResults.value = []
  showDownloadButton.value = false

  await ucitajStanje()
}

async function glasaj(id) {
  const tx = await contract.glasaj(id)
  await tx.wait()
  jeGlasao.value = true  
  await ucitajKandidate()
}

async function dodajKandidata() {
  if (!noviKandidat.value) return

  const postoji = kandidati.value.some(k => k.ime.toLowerCase() === noviKandidat.value.trim().toLowerCase())

  if (postoji) {
    greskaPoruka.value = 'Kandidat s tim imenom već postoji.'
    return
  }

  if (kandidati.value.length === 0 && savedResults.value.length > 0) {
    const obrisi = await contract.obrisiKandidate()
    await obrisi.wait()
    savedResults.value = []     
    showDownloadButton.value = false
    pobjednik.value = null
  }

  greskaPoruka.value = ''

  const tx = await contract.dodajKandidata(noviKandidat.value.trim())
  await tx.wait()

  await ucitajKandidate()
  noviKandidat.value = ''
}


async function obrisiKandidate() {
  const tx = await contract.obrisiKandidate()
  await tx.wait()
  await ucitajKandidate()
}

async function zaustaviGlasanje() {
  const broj = await contract.brojKandidata()
  const lista = []
  for (let i = 0; i < broj; i++) {
    const k = await contract.kandidati(i)
    if (k[1] !== '') {
      lista.push({ id: Number(k[0]), ime: k[1], brojGlasova: Number(k[2]) })
    }
  }

  lista.sort((a, b) => b.brojGlasova - a.brojGlasova)

  savedResults.value = lista 
  showDownloadButton.value = true 

  const tx = await contract.zaustaviGlasanje()
  await tx.wait()
  await ucitajStanje()

  if (intervalId.value) {
    clearInterval(intervalId.value)
  }

  pobjednik.value = await contract.dohvatiZadnjegPobjednika()
  kandidati.value = []
  jeGlasao.value = false
}

function downloadCSV() {
  const header = ['kandidat,broj_glasova']
  const rows = savedResults.value.map(k => `${k.ime},${k.brojGlasova}`)
  const csvContent = [header, ...rows].join('\n')

  const blob = new Blob([csvContent], { type: 'text/csv;charset=utf-8;' })
  const url = URL.createObjectURL(blob)

  const link = document.createElement('a')
  link.setAttribute('href', url)
  link.setAttribute('download', 'rezultati.csv')
  link.click()
}

async function obrisiKandidata(id) {
  const tx = await contract.obrisiKandidata(id)
  await tx.wait()
  await ucitajKandidate()
}
</script>
