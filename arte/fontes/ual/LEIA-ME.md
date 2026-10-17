# Universal Animation Library (Quaternius)

Pacote gratuito em CC0 (texto em `LICENSE.txt`), de [Quaternius](https://quaternius.com). Traz 43 animações num esqueleto com os nomes do manequim da Unreal.

O arquivo usado é `Unreal-Godot/UAL1_Standard.glb`, a versão sem movimento de raiz. Ele tem 7 MB e não fica no repositório. Para refazer os personagens, coloque esse arquivo em `p/ual/` do projeto de conversão (ver `../personagem_psx/LEIA-ME.md`).

Animações do pacote usadas no jogo:

| No pacote | No jogo |
| --- | --- |
| `Idle` | parado (aventureiro, com o braço da arma relaxado; monstros; mercador); base do arremesso da funda |
| `Jog_Fwd` | andar do aventureiro (com o braço da arma parado), corrida dos monstros |
| `Walk` | andar dos monstros |
| `Sprint` | correr (com o braço da arma parado) |
| `Sword_Idle` | guarda (com a arma pronta na frente); base das poses de golpe escritas à mão |
| `Crouch_Idle`, `Crouch_Fwd` | agachado parado e andando |
| `Roll` | esquiva |
| `Hit_Chest`, `Hit_Head` | dano (aventureiro, monstros) |
| `Death01` | morte |
| `Punch_Cross` | soco e golpe de adaga |
| `Idle_Talking` | mercador falando |

Até 16/10/2026 o golpe de espada usava `Sword_Attack` e a funda `Spell_Simple_Shoot`. Saíram na revisão das animações: o golpe de espada enterrava a lâmina no chão e o arremesso era feito com a mão esquerda, enquanto a funda fica na direita. Os dois agora são poses escritas em `../personagem_psx/personagens.gd`.
