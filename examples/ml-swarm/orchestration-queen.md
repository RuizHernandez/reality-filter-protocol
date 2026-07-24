# Example specialization: Queen/Primary orchestration topology

**This is an example, not a rule.** It shows how the universal core in
[`PROTOCOL.md`](../../PROTOCOL.md) §3 (State-verification over authority) was specialized into a
concrete authority topology for a 7-agent swarm ("Cerebro-Queen" orchestrating Coder, Arquitecto,
Revisor, and others, with "Primary" as a terminal interface). Copy this as a template for your
own swarm's topology, not as something this repository requires you to adopt.

Reproduced unedited, in the original Spanish, from `docs/devswarm/PROTOCOL.md` §3 (source commit
`ab08d13408add5c46c665e9e58dcb5684e662c53`) — see [LINEAGE.md](../../LINEAGE.md) for provenance.

---

## 3. TOPOLOGÍA DE ORQUESTACIÓN (Queen Supremacy)
- **Cerebro-Queen es la orquestadora suprema del enjambre.**
- **Primary (Cursor/CLI) actúa únicamente como un terminal (interfaz) de lectura/escritura y paso de mensajes.** Primary NO toma decisiones arquitectónicas, NO aprueba fases por sí solo (sin el `ACK` de la Queen) y NO despacha tareas de manera independiente.
- La Queen tiene total autonomía para escribir los archivos de orquestación (`INBOX-FROM-PRIMARY.md`, `ACK-QUEEN-*.md`, `PROMPT-*`) e instruir al resto de los workers (Coder, Arquitecto, Revisor) usando el sistema de archivos compartidos.
- Si Primary interfiere o alucina pasos adelantados, la Queen tiene autoridad absoluta para rechazar el estado, borrar los archivos falsificados y detener el pipeline hasta restablecer el orden lógico.
