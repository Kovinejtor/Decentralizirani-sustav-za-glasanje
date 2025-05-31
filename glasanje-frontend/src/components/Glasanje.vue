<template>
  <div class="min-h-screen flex flex-col items-center pt-12 pl-12 pr-12 rounded-lg bg-gray-900 text-gray-100">
    <h1 class="text-4xl font-bold mb-8 pt-2">Decentralizirano glasanje</h1>

    <div v-if="jeAdmin" class="flex flex-wrap gap-4 justify-center mb-8 pt-10">
      <input 
        v-model="noviKandidat" 
        class="border border-gray-600 bg-gray-800 text-white px-3 py-2 rounded focus:outline-none focus:ring-2 focus:ring-blue-500"
        placeholder="Unesi ime kandidata" 
      />

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

    <div v-if="(jeAdmin || glasanjeAktivno) && kandidati.length > 0" class="grid grid-cols-1 sm:grid-cols-2 md:grid-cols-3 gap-6">
      <div 
        v-for="k in kandidati" 
        :key="k.id" 
        class="bg-gray-800 border border-gray-700 p-6 rounded-xl shadow-md flex flex-col items-center justify-between"
      >
        <div>
          <h2 class="text-xl font-semibold text-center">{{ k.ime }}</h2>
          <p class="text-center mt-2 text-gray-400">{{ k.brojGlasova }} glasova</p>
        </div>
        <button
          class="mt-6 bg-blue-500 hover:bg-blue-600 text-white px-4 py-2 rounded disabled:opacity-50"
          @click="glasaj(k.id)"
          :disabled="!glasanjeAktivno"
        >
          Glasaj
        </button>
      </div>
    </div>

    <div v-if="pobjednik" class="mt-16 text-center">
      <p class="text-3xl font-semibold text-green-400">🏆 Pobjednik: {{ pobjednik }}</p>
    </div>
  </div>
</template>


<script setup>
import { ref, onMounted } from 'vue'
import { ethers } from 'ethers'
import { glasanjeAbi } from '../contracts/abi.js'
import contractMeta from '../contracts/contract-address.json'

const kandidati = ref([])
const noviKandidat = ref('')
const pobjednik = ref(null)
const jeAdmin = ref(false)
const glasanjeAktivno = ref(false)

const contractAddress = contractMeta.contractAddress
let contract

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
})

async function ucitajKandidate() {
  const broj = await contract.brojKandidata()
  const lista = []
  for (let i = 0; i < broj; i++) {
    const k = await contract.kandidati(i)
    lista.push({ id: k[0], ime: k[1], brojGlasova: k[2] })
  }
  kandidati.value = lista
}

async function ucitajStanje() {
  glasanjeAktivno.value = await contract.glasanjeAktivno()
}

async function glasaj(id) {
  const tx = await contract.glasaj(id)
  await tx.wait()
  await ucitajKandidate()
}

async function pokreniGlasanje() {
  const tx = await contract.pokreniGlasanje()
  await tx.wait()
  await ucitajStanje()
}

async function dodajKandidata() {
  if (!noviKandidat.value) return

  const tx = await contract.dodajKandidata(noviKandidat.value)
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
  const tx = await contract.zaustaviGlasanje()
  await tx.wait()
  await ucitajStanje()

  pobjednik.value = await contract.dohvatiPobjednika()
  kandidati.value = [] 
}
</script>
