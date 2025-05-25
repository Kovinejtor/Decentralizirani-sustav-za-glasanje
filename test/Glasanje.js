const { expect } = require("chai");
const { ethers } = require("hardhat");

describe("DecentraliziranoGlasanje", function () {
  let Glasanje;
  let glasanje;
  let admin;
  let birac;

  beforeEach(async function () {
    [admin, birac] = await ethers.getSigners();
    Glasanje = await ethers.getContractFactory("DecentraliziranoGlasanje");
    glasanje = await Glasanje.deploy();
    await glasanje.waitForDeployment();
  });

  it("Treba postaviti administratora ispravno", async function () {
    expect(await glasanje.administrator()).to.equal(admin.address);
  });

  it("Treba dodati kandidata", async function () {
    await glasanje.dodajKandidata("Alice");
    const kandidat = await glasanje.kandidati(0);
    expect(kandidat.ime).to.equal("Alice");
    expect(kandidat.brojGlasova).to.equal(0);
  });

  it("Treba registrirati birača", async function () {
    await glasanje.registrirajBiraca(birac.address);
    const biracData = await glasanje.biraci(birac.address);
    expect(biracData.registriran).to.be.true;
  });

  it("Treba omogućiti glasanje", async function () {
    await glasanje.dodajKandidata("Bob");
    await glasanje.registrirajBiraca(birac.address);
    await glasanje.pokreniGlasanje();

    await glasanje.connect(birac).glasaj(0);
    const kandidat = await glasanje.kandidati(0);
    expect(kandidat.brojGlasova).to.equal(1);
  });

  it("Ne smije dozvoliti glasanje ako nije aktivno", async function () {
    await glasanje.dodajKandidata("Charlie");
    await glasanje.registrirajBiraca(birac.address);

    await expect(glasanje.connect(birac).glasaj(0)).to.be.revertedWith("Glasanje nije aktivno.");
  });
});
