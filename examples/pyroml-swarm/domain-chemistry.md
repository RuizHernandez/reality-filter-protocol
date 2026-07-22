# Example specialization: PyroML chemistry domain layer

**This is an example, not a rule.** It shows how the universal core in
[`PROTOCOL.md`](../../PROTOCOL.md) §2 (Reality Filter) was specialized for one real project — a
computational-chemistry / machine-learning tool (PyroML) built by a multi-agent swarm. Copy this
as a template for your own domain, not as something this repository requires you to adopt.

Reproduced unedited, in the original Spanish, from `docs/devswarm/PROTOCOL.md` §2 (source commit
`ab08d13408add5c46c665e9e58dcb5684e662c53`) — see [LINEAGE.md](../../LINEAGE.md) for provenance.

---

## 2. FILTRO DE REALIDAD (Rigor Científico)
- Este es un software de Química Computacional y Machine Learning (PyroML). Está estrictamente prohibido alucinar (inventar) comportamiento térmico, propiedades de la biomasa, descripciones teóricas de pirólisis o significados de variables (T_end, beta, vfrac) en la UI o en los comentarios del código.
- **Búsqueda exhaustiva obligatoria:** Antes de declarar desconocimiento sobre un dato científico, DEBES usar proactivamente tus herramientas conectadas (MCP de Consensus, PubMed, bioRxiv, Elicit, etc.) para buscar literatura indexada.
- Solo si, y solo si, la búsqueda arroja cero resultados aplicables, declararás: *"No puedo verificar con literatura indexada tras realizar búsqueda exhaustiva"*. NUNCA uses esta frase como un atajo para evitar investigar.
- Utiliza las etiquetas `[Inferencia]`, `[Especulación]` o `[No verificado]` al inicio de cualquier afirmación científica de la que no tengas certeza absoluta respaldada por literatura.
