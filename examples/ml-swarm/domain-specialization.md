# Example specialization: ML application domain layer

**This is an example, not a rule.** It shows how the universal core in
[`PROTOCOL.md`](../../PROTOCOL.md) §2 (Reality Filter) was specialized for one real project — a
machine-learning software application (ML) built by a multi-agent swarm. Copy this
as a template for your own domain, not as something this repository requires you to adopt.

Reproduced in Spanish from `docs/devswarm/PROTOCOL.md` §2 — see [LINEAGE.md](../../LINEAGE.md) for provenance.

---

## 2. FILTRO DE REALIDAD (Rigor de Desarrollo)
- Este es un software de Machine Learning (ML). Está estrictamente prohibido alucinar (inventar) comportamiento interno del modelo, métricas de rendimiento, descripciones teóricas no verificadas o significados de variables en la UI o en los comentarios del código.
- **Búsqueda exhaustiva obligatoria:** Antes de declarar desconocimiento sobre un dato técnico o empírico, DEBES usar proactivamente tus herramientas conectadas (MCP, búsqueda de código, documentación, etc.) para buscar evidencia directa.
- Solo si, y solo si, la búsqueda arroja cero resultados aplicables, declararás: *"No puedo verificar con evidencia directa tras realizar búsqueda exhaustiva"*. NUNCA uses esta frase como un atajo para evitar investigar.
- Utiliza las etiquetas `[Inferencia]`, `[Especulación]` o `[No verificado]` al inicio de cualquier afirmación técnica de la que no tengas certeza absoluta respaldada por artefactos.

