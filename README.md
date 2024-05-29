# OpenPBKDF2
An open-source ASIC implementation of the PBKDF2 algorithm using SHA256 encryption

Authors: Davis Sauer, Eli Orona

![alt text](https://cdn.discordapp.com/attachments/1199124288377192479/1245222779008319560/image.png?ex=6658a055&is=66574ed5&hm=1108603c2021eb396eb416c2664c90964a190ceee113048969ae84f1afeeed76&)

## Development Log: 
Proposal
- https://www.youtube.com/watch?v=NauiHZyn6Ak

Demo 1
- https://www.youtube.com/watch?v=NauiHZyn6Ak

Demo 2
- https://youtu.be/THS_AII5xEg

Demo 3
- https://youtu.be/pvE8ix76I0A

Final Presentation
- https://www.youtube.com/watch?v=zfRz6UrT6so


## Architecture
### BSG_CHIP TOP MODULE
![alt text](https://cdn.discordapp.com/attachments/1199124288377192479/1237563761603248148/image.png?ex=665872d1&is=66572151&hm=e3cfed2839a8dbc1e66aa7a5ef069df036713428208fd2e69aaf13113f447de5&)

### KDA MODULE
![alt text](https://cdn.discordapp.com/attachments/1199124288377192479/1237563821933989951/image.png?ex=665872df&is=6657215f&hm=f4a22eb9a5f4ee0157b73033320a898036958554da33c934b15b19b25d1270c4&)

### PBKDF2 CHUNK MODULE
![alt text](https://cdn.discordapp.com/attachments/1199124288377192479/1245441903810576434/image.png?ex=6658c3a9&is=66577229&hm=550fd0ee29ccbbaca3e329ee812fa26f1a8cbefcd4c0a0223b94c998c2d8ef81&)

### HMAC_SHA256 MODULE
![alt text](https://cdn.discordapp.com/attachments/1199124288377192479/1245441997754470492/image.png?ex=6658c3bf&is=6657723f&hm=b2910716a91839d0dd65207827db1cc2998f29072699d6c97cf97fab8167f00c&)


## Limitations/Future Work 
- Maximum size of input password is 64 characters and maximum salt size is 55 characters
- Only supports HMAC_SHA256. Additional hashing algorithm options would make the chip more versatile
- Only supports output hash sizes of 32, 64, 96, 128 bytes. This could easily be extended by adding more PBKDF2 chunks to the KDA module
- Multicycle pathing with the hashing module has potential for perforamnce gains by removing unnecessary clk->q delays from the hashing datapath
- Further floorplanning and chip sizing optimization could improve datapaths
