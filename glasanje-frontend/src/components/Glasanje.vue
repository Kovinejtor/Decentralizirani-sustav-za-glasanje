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

if (!ethers.isAddress(contractAddress)) {
  console.error("Neispravna adresa ugovora");
}

let contract

async function switchToLocalhostNetwork() {
  const targetChainId = '0x7a69'; // hex za 31337

  try {
    const currentChainId = await window.ethereum.request({ method: 'eth_chainId' });

    if (currentChainId !== targetChainId) {
      // Pokušaj prebacivanja
      await window.ethereum.request({
        method: 'wallet_switchEthereumChain',
        params: [{ chainId: targetChainId }],
      });
    }
  } catch (switchError) {
    // Ako mreža još nije dodana, pokušaj je dodati
    if (switchError.code === 4902) {
      try {
        await window.ethereum.request({
          method: 'wallet_addEthereumChain',
          params: [{
            chainId: targetChainId,
            chainName: 'Localhost 8545',
            rpcUrls: ['http://127.0.0.1:8545'],
            nativeCurrency: {
              name: 'ETH',
              symbol: 'ETH',
              decimals: 18,
            },
          }],
        });
      } catch (addError) {
        console.error("Greška prilikom dodavanja mreže:", addError);
      }
    } else {
      console.error("Greška prilikom prebacivanja mreže:", switchError);
    }
  }
}


onMounted(async () => {
  await switchToLocalhostNetwork();
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

async function pokreniGlasanje() {
  try {
    await contract.pokreniGlasanje()
    alert("Glasanje je pokrenuto!")
  } catch (e) {
    alert("Greška: " + e.message)
  }
}


async function dodajKandidata() {
  try {
    if (!noviKandidat.value) return alert("Unesi ime kandidata")
    await contract.dodajKandidata(noviKandidat.value)
    await ucitajKandidate()
    noviKandidat.value = ""
  } catch (e) {
    alert("Greška: " + e.message)
  }
}
</script>
