<template>
  <div class="p-6 max-w-xl mx-auto">
    <h1 class="text-2xl font-bold mb-4">Decentralizirano Glasanje</h1>
    <div v-if="jeAdmin" class="mb-4 space-y-2">
        <input v-model="noviKandidat" class="border p-1 rounded" placeholder="Unesi ime kandidata" />
        <button @click="dodajKandidata" class="bg-blue-600 text-white px-3 py-1 rounded">Dodaj kandidata</button>
        <br />
        <button @click="pokreniGlasanje" class="bg-yellow-500 text-white px-3 py-1 rounded">Pokreni glasanje</button>
    </div>

    <div class="space-y-4">
      <div v-for="k in kandidati" :key="k.id" class="border p-2 rounded shadow">
        <p><strong>{{ k.ime }}</strong> — {{ k.brojGlasova }} glasova</p>
        <button
          class="bg-blue-500 text-white px-3 py-1 rounded"
          @click="glasaj(k.id)"
        >Glasaj</button>
      </div>

      <div class="mt-6">
        <p><strong>Pobjednik:</strong> {{ pobjednik || '—' }}</p>
        <button
          class="mt-2 bg-green-500 text-white px-3 py-1 rounded"
          @click="dohvatiPobjednika"
        >Prikaži pobjednika</button>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { ethers } from 'ethers'
import { glasanjeAbi } from '../contracts/abi.js'
import contractMeta from '../contracts/contract-address.json'

const kandidati = ref([])
const noviKandidat = ref('');
const pobjednik = ref(null)
const jeAdmin = ref(false)

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

async function glasaj(id) {
  await contract.glasaj(id)
  await ucitajKandidate()
}

async function dohvatiPobjednika() {
  pobjednik.value = await contract.dohvatiPobjednika()
}

async function pokreniGlasanje() {
  await contract.pokreniGlasanje()
}

async function dodajKandidata() {
  if (!noviKandidat.value) return
  await contract.dodajKandidata(noviKandidat.value)
  await ucitajKandidate()
  noviKandidat.value = ""
}
</script>
