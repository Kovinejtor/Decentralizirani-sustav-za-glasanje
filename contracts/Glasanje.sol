// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

contract DecentraliziranoGlasanje {
    address public administrator;

    struct Kandidat {
        uint id;
        string ime;
        uint brojGlasova;
    }

    struct Birac {
        bool registriran;
        bool glasao;
    }

    mapping(address => Birac) public biraci;
    mapping(uint => Kandidat) public kandidati;
    uint public brojKandidata;

    bool public glasanjeAktivno;

    constructor() {
        administrator = msg.sender;
    }

    modifier samoAdmin() {
        require(msg.sender == administrator, "Samo administrator.");
        _;
    }

    modifier samoKadAktivno() {
        require(glasanjeAktivno, "Glasanje nije aktivno.");
        _;
    }

    function dodajKandidata(string memory _ime) public samoAdmin {
        kandidati[brojKandidata] = Kandidat(brojKandidata, _ime, 0);
        brojKandidata++;
    }

    function registrirajBiraca(address _birac) public samoAdmin {
        require(!biraci[_birac].registriran, "Vec registriran.");
        biraci[_birac] = Birac(true, false);
    }

    function pokreniGlasanje() public samoAdmin {
        glasanjeAktivno = true;
    }

    function zaustaviGlasanje() public samoAdmin {
        glasanjeAktivno = false;
    }

    function glasaj(uint _kandidatId) public samoKadAktivno {
        require(biraci[msg.sender].registriran, "Niste registrirani.");
        require(!biraci[msg.sender].glasao, "Vec ste glasali.");
        require(_kandidatId < brojKandidata, "Neispravan kandidat.");

        biraci[msg.sender].glasao = true;
        kandidati[_kandidatId].brojGlasova++;
    }

    function dohvatiPobjednika() public view returns (string memory ime) {
        require(!glasanjeAktivno, "Glasanje je jos aktivno.");
        uint maxGlasova = 0;
        uint pobjednikId;

        for (uint i = 0; i < brojKandidata; i++) {
            if (kandidati[i].brojGlasova > maxGlasova) {
                maxGlasova = kandidati[i].brojGlasova;
                pobjednikId = i;
            }
        }

        return kandidati[pobjednikId].ime;
    }
}
