# Filtro de Realidad v5 + Anti-Sycophancy

[English](README.md) | **Español**

Un protocolo de conducta público, agnóstico de modelo y citable, para asistentes de código con IA y enjambres multi-agente.

[![Licencia: CC BY 4.0](https://img.shields.io/badge/License-CC%20BY%204.0-lightgrey.svg)](LICENSE)

**Nombre del protocolo:** *Filtro de Realidad v5* (conservado de su origen privado). **Versión de la release:** `v1.2.0` (ver [LINEAGE.md](LINEAGE.md) para entender por qué el nombre del protocolo y el semver de la release son contadores distintos). **Último DOI archivado/citable:** [10.5281/zenodo.21499994](https://doi.org/10.5281/zenodo.21499994) — cubre el snapshot `v1.0.0`; aquí se añadirá el DOI específico de `v1.2.0` cuando Zenodo lo emita.

## Skills de dominio incluidos

Este repo incluye los skills desarrollados para el flujo de investigación en ingeniería bioquímica y bioprocesos del Dr. Itan Homero Ruiz-Hernández:

- **`bio-ruiz-hernandez`** — la especialización insignia, y la demostración más clara de lo que una capa de dominio aporta más allá de una simple adaptación del protocolo. Tres cosas lo hacen diferente: (1) generaliza el auto-chequeo visual n=5 en una **auditoría de manuscritos n=10** — cinco pases de contenido, cuatro de ética, uno de formato — aplicada a cada borrador; (2) añade una **capa de ética de IA en investigación** que el protocolo núcleo no cubre: el agente actúa como herramienta y nunca como autor, los datos sensibles deben anonimizarse y computarse localmente, todo resultado analítico se entrega con su código reproducible, y un aviso de transparencia bilingüe (ES/EN) declara la participación de la IA — de modo que el skill funciona también como una política de uso de IA lista para revistas; (3) impone **invariantes editoriales duros** (nomenclatura microbiana en itálicas, notación Unicode limpia, citación única en negritas por bloque, manejo de figuras EPS con Ghostscript sin marca de agua).
- **`numerical-data-analysis`** — reglas anti-fuga de datos (`fit` solo en Train, pipelines obligatorios, SMOTE dentro de los folds de CV), selección de scaler según distribución y algoritmo, y una directiva Julia/SciML para modelado cinético de bioprocesos con ODEs.

## Qué es esto

Tres reglas de conducta agnósticas de dominio — anti-sycophancy en ambas direcciones, filtrado de realidad verifica-antes-de-afirmar, y verificación-de-estado-sobre-autoridad para topologías de agentes orquestador/subordinado — escritas una sola vez en [`PROTOCOL.md`](PROTOCOL.md) y adaptadas a plataformas específicas:

- **Canónico:** [`PROTOCOL.md`](PROTOCOL.md)
- **Claude Code:** [`adapters/claude-code/SKILL.md`](adapters/claude-code/SKILL.md)
- **Antigravity:** [`adapters/antigravity/SKILL.md`](adapters/antigravity/SKILL.md)
- **Cursor:** [`adapters/cursor/reality-filter.mdc`](adapters/cursor/reality-filter.mdc)
- **Gemini CLI (skills de dominio):** [`adapters/gemini-cli/`](adapters/gemini-cli/) — skills editoriales de investigación en bioprocesos + análisis de datos numéricos (ver **Skills de dominio incluidos** arriba)
- **Otras plataformas** (ChatGPT, Windsurf, …): aún sin adapter oficial — ver [CONTRIBUTING.md](CONTRIBUTING.md) para la guía de portado.

Es prosa conductual, no código ejecutable. Su valor es la portabilidad de reglas de conducta entre modelos, y su citabilidad como artefacto académico.

## Por qué existe

Los modelos frontera ya están entrenados hacia la calibración y la honestidad. Así que las mitades *anti-sycophancy* y *verifica-antes-de-afirmar* de este protocolo en su mayor parte refuerzan un comportamiento hacia el que un buen modelo base ya tiende — no afirmamos haberlas inventado.

La parte que un modelo base **no** hace por sí solo son los **límites explícitos de autoridad entre un agente orquestador y sus subordinados** — quién puede decidir, quién solo puede reportar, y la regla de que el orquestador verifica el estado real (git, logs, archivos) en vez de confiar en la narrativa de cualquier agente, *incluida la suya propia*. Esta capa de gobernanza es la contribución real del protocolo: no es novedosa en abstracto (least-privilege y los patrones orquestador-trabajador la preceden por décadas), pero sí es una articulación portable, a nivel de prompt, para enjambres de agentes LLM.

### La mitad social de una lección en dos partes

Una instrucción conversacional **no** es enforcement técnico. Un prompt que dice "el subordinado no puede actuar sin aprobación" constriñe a un modelo cooperativo; no *detiene* a uno determinado o defectuoso — solo una compuerta real (un hook `preToolUse`, una ACL, un sandbox) lo hace.

- **Este protocolo** demuestra la mitad *social/prompt*.
- Una investigación adversarial paralela sobre el sistema de hooks de Cursor ([Cursor-Hooks-Minimal-Test](https://github.com/RuizHernandez/Cursor-Hooks-Minimal-Test)) demostró la mitad *técnica* — y por qué es no-opcional: un hook `beforeShellExecution` que llegó con payload vacío cayó por defecto en *allow*, dejando correr un comando de shell que un `preToolUse` previo ya había denegado. La regla a nivel prompt es necesaria; no es suficiente.

Usa este protocolo para la mitad social. No lo confundas con la técnica.

## Ejemplos resueltos

[`examples/ml-swarm/`](examples/ml-swarm/) muestra el núcleo universal especializado para un proyecto real: una aplicación de software de machine learning construida por un enjambre de 7 agentes. Se reproduce sin diluir desde la fuente privada, etiquetada como ejemplo — cópiala como plantilla, no como una regla que este repositorio te exija adoptar.

[`examples/bioprocess-research/`](examples/bioprocess-research/) muestra la misma especialización para un dominio de investigación: redacción científica en ingeniería bioquímica (`bio-ruiz-hernandez`, con su auditoría n=10 y ética de IA en investigación) y análisis de datos numéricos (`numerical-data-analysis`, con reglas anti-fuga de datos y directiva Julia/SciML), implementados como dos skills instalables de Gemini CLI ([`adapters/gemini-cli/`](adapters/gemini-cli/)).

## Evidencia y limitaciones

**Esto no es una evaluación controlada.** No hay aquí ningún estudio A/B — misma tarea, con regla vs. sin regla, a través de múltiples modelos. Cada ítem abajo está graduado por *cómo fue observado*, y los grados no son iguales. Confundirlos sería exactamente el error que este protocolo existe para prevenir.

**Tier 1 — revisado por un segundo agente independiente.** Un agente distinto (una sesión diferente de Claude Code, no la del agente bajo la regla) revisó un extracto de transcripción que el usuario pegó en esa segunda conversación — no el log crudo de sesión del agente original — en el que el agente original describe haber rechazado una atribución aduladora de "tú detectaste este bug" y haberla etiquetado `[unverified]`. El segundo agente confirmó que esa autodescripción estaba bien calibrada: distinguió correctamente comportamiento observable de una afirmación causal introspectiva no verificable; no confirmó que el evento subyacente ocurriera exactamente como se describió. Esto es verificación de transcripción-retransmitida-por-el-usuario, no acceso directo al log.

**Tier 2 — autorreporte del agente bajo la regla, no verificado independientemente.** El mismo agente reporta dos incidentes más de una sesión anterior que ningún tercero revisó: una autoacusación retractada cuando la evidencia de git la contradijo, y un casi-rechazo falso detectado al re-verificar la fuente. Verificamos que PROTOCOL.md existe con este contenido; **no** verificamos que esos eventos específicos ocurrieran como se describen. Trátalo como autorreporte.

**Tier 3 — autorreporte del usuario sobre uso diario.** El autor corre el protocolo en un prompt persistente de escritorio y observa al modelo invocándolo visiblemente fuera del proyecto original ("per your reality filter and anti-sycophancy…") durante navegación/codificación ordinaria. Autorreporte de usuario, no medición.

**Contexto, no un ensayo controlado:** estas observaciones provienen de una sesión de ingeniería multi-día y multi-agente (una orquestación de 7 agentes construyendo una herramienta de ML para química computacional) donde ocurrió un fallo real de gobernanza durante trabajo normal — no un red-team deliberado. (El trabajo genuinamente *adversarial* es la investigación separada de [hooks de Cursor](https://github.com/RuizHernandez/Cursor-Hooks-Minimal-Test), que *sí* fue una sonda deliberada).

Lo que explícitamente **no podemos** afirmar: que la regla *causó* un comportamiento dado, en vez de que el modelo base lo produjera de todos modos. Separar ambos requeriría el estudio controlado que no hemos ejecutado. Contribuciones de tal estudio son bienvenidas.

Ver [EVIDENCE.md](EVIDENCE.md) para la versión extendida de esta sección, incluyendo el detalle de la cadena de evidencia detrás del Tier 1 y los hallazgos cuantificados de los hooks de Cursor detrás de la referencia a la "mitad de enforcement técnico".

## Cómo citar

```
Ruiz-Hernández, I. (2026). Filtro de Realidad v5 + Anti-Sycophancy:
A model-agnostic conduct protocol for AI coding assistants (v1.0.0).
Zenodo. https://doi.org/10.5281/zenodo.21499994
```

`CITATION.cff` también está presente para la función "Cite this repository" de GitHub.

- ORCID: [0000-0001-8075-482X](https://orcid.org/0000-0001-8075-482X)
- Google Scholar: `user=BvW7db0AAAAJ`
- ResearchGate: `Itan-Ruiz-Hernandez`

## Contribuir

Ver [CONTRIBUTING.md](CONTRIBUTING.md) — portar el protocolo a una nueva plataforma, o contribuir una evaluación controlada que este repositorio aún no tiene.

## Procedencia

Ver [LINEAGE.md](LINEAGE.md) para conocer el origen de este protocolo y cómo la release pública mapea a su historia de versiones privada.

## Licencia

[CC BY 4.0](LICENSE). La atribución viaja con las copias.

## Relacionados

- [Cursor-Hooks-Minimal-Test](https://github.com/RuizHernandez/Cursor-Hooks-Minimal-Test) — la mitad de enforcement técnico de esta lección en dos partes.
