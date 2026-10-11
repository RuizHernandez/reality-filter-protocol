# Revisión científica del texto disponible y propuesta de redacción

## 1. Alcance

Se revisaron los documentos científicos o cuasi científicos **presentes en el repositorio**:
`README.md`, `README.es.md`, `EVIDENCE.md`, `PROTOCOL.md` (cambios de versión y bibliografía),
`validation/REPORT.md`, `validation/live-agent-trial-1/TRIAL.md` y `validation/ab-study/PROTOCOL-AB.md`.
El "companion research paper" que mencionan `PROTOCOL.md` (v1.3.0) y `REPORT.md` **no está en el
repositorio**: su revisión es **NO VERIFICABLE** en esta auditoría. No se introdujo ninguna
referencia bibliográfica nueva; las únicas fuentes externas consultadas son las ya citadas, releídas
en sus registros primarios (arXiv, Crossref, página del editor, Zenodo).

**Valoración general.** El texto del repositorio es, en su mayor parte, cuidadoso: separa niveles de
evidencia (Tier 1–3), declara la ausencia de un estudio controlado y evita atribuir efectos causales
al protocolo. Los problemas detectados son puntuales y se concentran en (i) formulaciones
promocionales del README, (ii) dos citas que exceden lo que dice su fuente y (iii) afirmaciones sobre
la validación técnica que omitían las condiciones de las que dependía su reproducción.

## 2. Afirmaciones examinadas

| # | Ubicación | Afirmación (resumen) | Estado | Propuesta |
|---|---|---|---|---|
| 1 | `README.md` l. 5 | "model-agnostic" | Propiedad de **diseño**; NO VERIFICADA empíricamente (sin evaluación multi-modelo) | "designed to be model-agnostic; portability across models has not been evaluated" |
| 2 | `README.md` l. 111 | "This protocol demonstrates the social/prompt half" | Sobredimensionada: no hay medición del efecto conductual | "addresses" en lugar de "demonstrates" |
| 3 | `README.md` l. 81–90 | Los modelos de frontera ya tienden a la calibración; lo que no hacen solos son límites de autoridad | Hipótesis de motivación sin evidencia citada ni medida | Rotularla como motivación (`[S]`), no como hallazgo |
| 4 | `README.md` l. 102 | Las reglas anti-fuga hacen la fuga "impossible by construction" | Sobredimensionada: son reglas en prosa; la imposibilidad solo se da si el pipeline las impone en código | "make it structurally avoidable when enforced in code" |
| 5 | `README.md` l. 22–29 | La skill sirve como "journal-ready AI-use policy" | NO VERIFICADA: ninguna revista evaluó el texto | "can serve as a starting point for a journal AI-use statement" |
| 6 | `README.md` (antes de esta auditoría) | "Two harnesses … All four run in CI" | Desactualizada (había tres suites) | **Corregida** en esta rama |
| 7 | `README.md`, `README.es.md` | DOI "último" = v1.0.0; "se añadirá el de v1.4.0" | Desactualizada (Zenodo publicó v1.5.0 el 2026-09-02) | **Corregida** en esta rama, verificada contra la API de Zenodo |
| 8 | `EVIDENCE.md` l. 29 | Tier 1: "an independent model, not the one under review" | Ambigua: era otra sesión del mismo sistema (Claude Code); independencia operativa, no de modelo | "a separate session (same model family), not the session under review" |
| 9 | `EVIDENCE.md` l. 70 | No se usan "validated/proven/tested" para el efecto conductual | **Respaldada**: las apariciones de "validated/tested" se refieren a controles de artefacto | Sin cambio |
| 10 | `PROTOCOL.md` v1.3.0, `REPORT.md` | 13/13 escenarios validados; "every PASS/FAIL is the exit code of an actual git commit" | Respaldada **bajo condiciones**: con ruta larga en Windows el arnés producía 5 PASS sin repositorio; el código de salida existía, pero no era atribuible al control | Añadir el entorno; **corregido** el oráculo y documentado en `REPORT.md` |
| 11 | `LINEAGE.md` v1.5.0 | `mutate_check.sh` = mutation testing sistemático | **FALLIDA**: herramienta inerte | **Corregida** con el formato obligatorio de corrección |
| 12 | `PROTOCOL.md` bibliografía (Young 2026) | "sycophancy-hint acknowledgment as low as 53.9%" | PARCIAL (tasa agregada presentada como mínimo) | §3 |
| 13 | `PROTOCOL.md` bibliografía (Kraidia 2026) | "Best-of-N/RAG amplify rather than mitigate the effect" | PARCIAL (la fuente dice "can unintentionally amplify") | §3 |
| 14 | `PROTOCOL.md` bibliografía (Young; Kraidia; Yan) | 41 832 corridas; 12 modelos; ~87,5 % vs ~28,6 %; 10–40 %; 72,50 % → 14,17 % | Respaldadas a nivel de **resumen** | Sin cambio; texto completo no auditado |
| 15 | `PROTOCOL.md` §3.12 | Generaliza Kraidia et al. y Yan et al. | Correctamente rotulada como derivada de la literatura | Sin cambio |
| 16 | `TRIAL.md` | Ensayo N=1 con modelo `auto` | Correctamente acotado; el modelo exacto no es recuperable | Añadir que el identificador `auto` impide la replicación exacta |
| 17 | Toda la documentación | Eficacia en reducción de alucinaciones o complacencia | **No se afirma** en ningún documento; ninguna evidencia lo respaldaría | Mantener |

## 3. Correcciones bibliográficas propuestas (texto canónico en inglés; no aplicadas)

- **Young (2026), arXiv:2603.22582v1.**
  Actual: "sycophancy-hint acknowledgment as low as 53.9%".
  Propuesta: "an aggregate acknowledgment rate of 53.9% for sycophancy hints, among the lowest of the
  six hint categories (per-model faithfulness ranged from 39.7% to 89.9%)".
- **Kraidia et al. (2026), doi:10.1038/s41598-026-42705-7.**
  Actual: "inference-time techniques like Best-of-N/RAG amplify rather than mitigate the effect".
  Propuesta: "inference-time techniques such as Best-of-N and RAG can unintentionally amplify the
  effect rather than mitigate it".

Una vez aplicadas, `scripts/claim-support.tsv` debe actualizar `claim_text` y pasar C2 y C5 a
SUPPORTED con nueva fecha de comprobación; `check-claim-support.sh` falla mientras no se haga, por
diseño.

## 4. Texto científico revisado (propuesta)

### 4.1 Descripción del método

El Filtro de Realidad v5 + Anti-Sycophancy es un protocolo de conducta, formulado en lenguaje natural,
para asistentes de programación basados en modelos de lenguaje y para sistemas multiagente. Consta de
tres reglas generales —rechazo de la complacencia en ambas direcciones, verificación contra la fuente
antes de afirmar y verificación del estado por encima de la autoridad en topologías de orquestación—,
de un sistema de cuatro etiquetas epistémicas (empírica, inferencia, especulación, no verificada) y de
un conjunto de reglas operativas derivadas de un incidente documentado y de la literatura sobre
sistemas multiagente. El protocolo se diseñó para ser independiente del modelo subyacente; esta
independencia constituye una propiedad de diseño y no ha sido evaluada empíricamente.

### 4.2 Implementación

El protocolo se distribuye como texto canónico (`PROTOCOL.md`) y adaptadores para cinco plataformas.
Una parte de las reglas dispone, además, de mecanismos de cumplimiento externos al modelo: *hooks* de
git para la inmutabilidad de especificaciones (§3.2) y la detención técnica (§3.10), verificadores de
entregables (§3.8) y de localización de *stash* (§3.3), un verificador de transcripciones para la
independencia entre pares (§3.12) y, desde la auditoría de 2026-10-11, un verificador estructural de
las etiquetas epistémicas y de la caducidad de la evidencia (§2), así como un registro de respaldo
documental de las cifras citadas. El resto de las reglas depende exclusivamente de que el modelo siga
las instrucciones. Los mecanismos externos verifican la **forma** de un artefacto o de una
transcripción; ninguno verifica la veracidad de una afirmación.

### 4.3 Validación técnica

Los mecanismos externos se evaluaron mediante pruebas sintéticas que no involucran modelos de
lenguaje. En un entorno Windows 11 con Git Bash 5.3 y git 2.55, y con las condiciones que se indican,
se reprodujeron los resultados registrados previamente: 13 de 13 escenarios del *replay* del incidente
(con un directorio temporal de ruta corta), 8 de 8 escenarios de verificación entre pares (con `jq`
disponible) y 13 de 13 escenarios de las puertas de dominio. La auditoría identificó que, fuera de esas
condiciones, el arnés de *replay* informaba como superados escenarios cuyo rechazo se debía a un fallo
del entorno y no al control evaluado; los arneses se corrigieron para exigir la identificación del
control que rechaza y para declarar los errores de entorno. Pruebas adversariales locales revelaron
cinco vías de evasión en los *hooks* —una de ellas detectada por una revisión independiente posterior y
no por la primera pasada de la auditoría— y un comportamiento de Git for Windows por el cual un *hook*
terminado por una señal se considera satisfactorio. Tras las correcciones, una suite de 53 escenarios
se superó en su totalidad, y 27 de esos escenarios fallan al restituir los archivos originales. Las
pruebas de mutación, ahora operativas, eliminaron todos los mutantes aplicables de los cuatro
verificadores con un conjunto reducido de cuatro operadores. Estos resultados establecen el
funcionamiento técnico de los controles bajo las condiciones especificadas; no establecen ningún
efecto sobre el comportamiento de un modelo.

### 4.4 Resultados experimentales disponibles

No se dispone de resultados experimentales controlados. La evidencia conductual existente consiste
en tres niveles de observación no controlada (revisión de un extracto de transcripción por una sesión
separada del mismo sistema, autoinforme del agente y autoinforme del usuario) y en un único ensayo con
un agente real (N = 1, modelo no identificado de forma exacta). Ninguno permite atribuir al protocolo un
efecto causal sobre la frecuencia de alucinaciones, de afirmaciones sin respaldo o de respuestas
complacientes.

### 4.5 Limitaciones

(i) Ausencia de un estudio controlado; (ii) los controles externos dependen de un rol autodeclarado
(`AGENT_ROLE`), pueden eliminarse desde una *shell* sin restricciones y no alcanzan a señales que no
pueden ignorarse; (iii) los verificadores de transcripciones operan sobre un esquema propio que ninguna
plataforma emite todavía, y sus listas de comandos son heurísticas; (iv) el respaldo documental de las
citas se comprobó a nivel de resumen y dos de seis cifras se apartan parcialmente de su fuente; (v) la
independencia entre verificadores se controla en su dimensión operativa (lectura propia del artefacto),
no en la documental ni en la estadística; (vi) los resultados de modelos remotos no son exactamente
reproducibles, porque los proveedores modifican los modelos bajo una misma denominación; (vii) el
protocolo es público y pudo formar parte de los datos de entrenamiento de los modelos que se evalúen.

### 4.6 Estrategias de mitigación

Registro de procedencia y estado de respaldo para cada cifra citada; registro obligatorio de
búsqueda para toda afirmación no verificada o de ausencia; regla de la parte más débil para
afirmaciones compuestas; caducidad verificable de la evidencia sobre estado mutable; *hooks* que
fallan de forma cerrada; registro del entorno de cada ejecución; preregistro verificado por *hash*,
identificador exacto del modelo y ciego ampliado en el aparato experimental; brazo de control de
longitud y brazos de ablación por sección; revisión del código de verificación por un agente con
contexto separado, declarando que su independencia es operativa y no estadística.

### 4.7 Trabajo futuro

Ejecutar el estudio controlado descrito en `research/PLAN_EXPERIMENTAL_AB.md` (control sin protocolo,
control de longitud y ablaciones; al menos dos proveedores de modelos); medir la concordancia entre
anotadores en la asignación de etiquetas epistémicas; conectar los verificadores de transcripciones a
una plataforma real; incorporar un control del lado del servidor que el agente evaluado no pueda
modificar; auditar el texto completo de las fuentes citadas; y estimar la dependencia estadística de los
errores entre verificadores con configuraciones de contexto, fuentes y modelos diferenciados.
