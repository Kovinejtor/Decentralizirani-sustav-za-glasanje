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

    address[] public listaBiraca; 

    bool public glasanjeAktivno;
    string public zadnjiPobjednik;

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

    function obrisiKandidate() public samoAdmin {
        for (uint i = 0; i < brojKandidata; i++) {
            delete kandidati[i];
        }
        brojKandidata = 0;
    }

    function obrisiKandidata(uint _id) public samoAdmin {
        require(_id < brojKandidata, "Neispravan ID");
        delete kandidati[_id];
    }

    function pokreniGlasanje() public samoAdmin {
        glasanjeAktivno = true;
    }

    function zaustaviGlasanje() public samoAdmin {
        glasanjeAktivno = false;
        resetirajBirece(); 
        zadnjiPobjednik = dohvatiPobjednika();
    }

    function glasaj(uint _kandidatId) public samoKadAktivno {
        require(!biraci[msg.sender].glasao, "Vec ste glasali.");
        
        biraci[msg.sender].glasao = true;
        biraci[msg.sender].registriran = true;

        if (!jeNaListi(msg.sender)) {
            listaBiraca.push(msg.sender);
        }

        kandidati[_kandidatId].brojGlasova++;
    }

    function dohvatiZadnjegPobjednika() public view returns (string memory) {
        return zadnjiPobjednik;
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

    function resetirajBirece() internal {
        for (uint i = 0; i < listaBiraca.length; i++) {
            biraci[listaBiraca[i]].glasao = false;
            biraci[listaBiraca[i]].registriran = false;
        }
        delete listaBiraca; 
    }

    function jeNaListi(address _addr) internal view returns (bool) {
        for (uint i = 0; i < listaBiraca.length; i++) {
            if (listaBiraca[i] == _addr) {
                return true;
            }
        }
        return false;
    }

    function dohvatiSveKandidate() public view returns (Kandidat[] memory) {
        Kandidat[] memory sviKandidati = new Kandidat[](brojKandidata);
        for (uint i = 0; i < brojKandidata; i++) {
            sviKandidati[i] = kandidati[i];
        }
        return sviKandidati;
    }   

}
