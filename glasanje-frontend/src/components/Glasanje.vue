<template>
  <div class="p-6 max-w-xl mx-auto">
    <h1 class="text-2xl font-bold mb-4">Decentralizirano Glasanje</h1>

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

const kandidati = ref([])
const pobjednik = ref(null)

const contractAddress = "0x5FbDB2315678afecb367f032d93F642f64180aa3" // zamijeni ako treba

if (!ethers.isAddress(contractAddress)) {
  console.error("Neispravna adresa ugovora");
}

let contract

onMounted(async () => {
  const provider = new ethers.BrowserProvider(window.ethereum)
  const signer = await provider.getSigner()

  contract = new ethers.Contract(contractAddress, glasanjeAbi, signer)

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
  try {
    await contract.glasaj(id)
    await ucitajKandidate()
  } catch (e) {
    alert("Greška: " + e.message)
  }
}

async function dohvatiPobjednika() {
  try {
    pobjednik.value = await contract.dohvatiPobjednika()
  } catch (e) {
    alert("Ne možeš još dohvatiti pobjednika.")
  }
}
</script>
