const { buildModule } = require("@nomicfoundation/hardhat-ignition/modules");

module.exports = buildModule("GlasanjeModule", (m) => {
  const glasanje = m.contract("DecentraliziranoGlasanje", []);
  return { glasanje };
});
