---
name: numerical-data-analysis
description: "Protocolo de preprocesamiento y modelado para datos numéricos. Usa este skill al preparar datasets tabulares, elegir técnicas de normalización/escalado, imputar valores faltantes, construir pipelines de scikit-learn o entrenar modelos de ML: aplica reglas estrictas contra Data Leakage (fit solo en Train), selección de scaler según distribución y algoritmo, y justificación metodológica con literatura (Elicit/OpenAlex)."
---

# 📊 Protocolo de Análisis de Datos Numéricos

**Canonical source:** [`PROTOCOL.md`](../../../PROTOCOL.md) at the repository root. This skill is a **domain specialization** of that protocol for numerical data work — if this text and `PROTOCOL.md` ever disagree on conduct rules, `PROTOCOL.md` is correct.

Directivas matemáticas y metodológicas obligatorias al asistir al usuario en ciencia de datos, preprocesamiento y entrenamiento de modelos de Machine Learning sobre datos numéricos.

## 1. REGLAS DURAS — PREVENCIÓN DE DATA LEAKAGE (PROHIBIDO violarlas)

1. **Regla de Oro:** Todo transformador que aprenda parámetros de los datos — escalador (`MinMaxScaler`, `StandardScaler`, `RobustScaler`), **imputador** (`SimpleImputer`, `KNNImputer`), **selector de características**, **codificador** (target/one-hot) — debe ajustarse (`fit`) **EXCLUSIVAMENTE con los datos de entrenamiento (Train)**.
2. **PROHIBIDO** aplicar `fit_transform` a todo el dataset antes del `train_test_split`. Test y Validación solo reciben `transform()` con los parámetros aprendidos del Train.
3. **PROHIBIDO** aplicar SMOTE u otro oversampling antes del split o fuera del fold de validación cruzada. Usa `imblearn.pipeline.Pipeline` para que el remuestreo ocurra solo dentro del Train de cada fold.
4. **Estructura obligatoria:** encapsula preprocesamiento + modelo en `sklearn.pipeline.Pipeline` (o `ColumnTransformer` para tipos de variable mixtos) de modo que el `fit` se ejecute por fold dentro de `cross_val_score`/`GridSearchCV`. Un pipeline bien construido hace imposible la fuga por descuido.
5. El análisis exploratorio que informe decisiones de modelado (correlaciones, selección de variables) se hace sobre Train, no sobre el dataset completo.
6. **Ejemplo canónico de la Regla de Oro — features derivadas de estadísticas globales:** cualquier feature construida a partir de estadísticas de una columna completa (media, mediana, moda, percentiles, frecuencias) debe computarse EXCLUSIVAMENTE sobre Train. Escribir `df['feature'] = df['columna'].mean()` antes del `train_test_split` es data leakage aunque no uses un transformador formal ni un `fit`: el valor filtra información de Test hacia Train. La forma correcta es un transformador dentro del Pipeline (p. ej. `feature-engine`) o el cálculo manual sobre Train seguido de `transform` sobre Test.

## 2. SELECCIÓN DE TÉCNICA DE ESCALADO

| Técnica | Usar cuando | Evitar cuando |
|---------|-------------|---------------|
| **Z-Score / StandardScaler** (media 0, std 1) | Por defecto en algoritmos basados en distancias (KNN) y optimización por gradiente (Regresión Logística, Redes Neuronales, SVM, PCA) | Distribuciones con outliers extremos |
| **RobustScaler** (mediana e IQR) | Distribución asimétrica severa y outliers extremos que no pueden eliminarse — **obligatorio en ese caso** | — |
| **MinMaxScaler** [0, 1] | Sin outliers extremos y/o cota estricta requerida (p. ej. entrada de redes neuronales) | Con outliers: un solo valor extremo comprime la masa de datos en un rango minúsculo |
| **MaxAbsScaler** | Matrices dispersas (sparse, TF-IDF): conserva la estructura de ceros | Datos densos con outliers |
| **Sin escalado** | Árboles y ensambles de árboles (Random Forest, XGBoost, LightGBM): son invariantes a la escala porque operan por umbrales | — |

## 3. FLUJO DE TRABAJO ESTÁNDAR

1. **EDA** sobre el dataset completo con fines descriptivos (`fg-data-profiling`, §4): ceros, nulos, correlaciones de Pearson/Spearman, asimetría.
2. **Split** temprano: `train_test_split` (estratificado si es clasificación) ANTES de cualquier transformación ajustable.
3. **Pipeline**: imputación → escalado (según §2) → modelo, todo dentro de `Pipeline`/`ColumnTransformer`.
4. **Validación cruzada** sobre Train; ajuste de hiperparámetros con `GridSearchCV`/`RandomizedSearchCV` envolviendo el pipeline.
5. **Evaluación final** una sola vez sobre Test; reporta métricas con intervalo o varianza entre folds, y etiqueta cada afirmación según el Filtro de Realidad del skill `bio-ruiz-hernandez` ([Empírico]/[Inferencia]/[Especulación]/[No verificado] en entregables formales; `[E]`/`[I]`/`[S]`/`[U]` en salida operativa, con la leyenda declarada una vez — `PROTOCOL.md` §2).

## 4. LIBRERÍAS Y HERRAMIENTAS PREFERIDAS

- **Manejo de Profiling y Migraciones:** `ydata-profiling` fue renombrado a `fg-data-profiling` por sus autores y el paquete viejo ya no recibe actualizaciones ni correcciones (riesgo creciente de incompatibilidad con Python reciente). Instala con `pip install fg-data-profiling` e importa `from data_profiling import ProfileReport`. Si detectas scripts legacy del usuario con `import ydata_profiling` o `import pandas_profiling`, adverte la descontinuación y migra los imports. Verifica la instalación con `pip show fg-data-profiling` antes de usarlo.
  - ⚠️ **ALERTA — Dependencia no declarada (`pkg_resources`):** `fg-data-profiling` requiere `pkg_resources`, que `setuptools` eliminó a partir de la versión 81. Síntoma: `ModuleNotFoundError: No module named 'pkg_resources'` al importar. Solución: fija `setuptools==80.9.0` en ese intérprete (`pip install "setuptools==80.9.0"`). Nunca actualices `setuptools` por encima de 80.x en un entorno donde se use profiling sin avisar al usuario, porque romperá el import.
- **Ingeniería de características:** `feature-engine` (github.com/feature-engine/feature_engine) — transformers compatibles con scikit-learn (`fit`/`transform`): imputación compleja, codificación categórica, discretización, tratamiento de outliers (Winsoriser) y selección de variables. Respeta §1: todo `fit` solo con Train.
- **Modelos tabulares avanzados:** `TabPFN` para clasificación zero-shot en datasets pequeños/medianos; TabPFN v2 soporta hasta ~10,000 muestras y ~500 variables.
- **Ecosistema Julia (SciML) para Bioprocesos:** Cuando la tarea implique modelado cinético, sistemas de ecuaciones diferenciales ordinarias (ODEs) o dinámica de bioprocesos (ej. crecimiento microbiano, consumo de sustrato), propón y estructura código en **Julia** con `SciML` (`DifferentialEquations.jl`), superior a SciPy en este nicho por su compilación JIT. **Precondición:** verifica primero que `julia --version` responda en el sistema; si Julia no está instalado, informa al usuario y ofrece instalarlo o, con su aprobación, genera el equivalente en SciPy declarado como fallback. Para SciML en Python consulta `awesome-sciml` (github.com/Mathepia/awesome-sciml): PySINDy (identificación de dinámicas), PySR (regresión simbólica), SALib (sensibilidad global), PyDMD.
- **Justificación científica:** sugiere consultas estructuradas en Elicit u OpenAlex (ej. "Impact of missing data imputation methods on Random Forest models") para defender la metodología elegida con literatura.

## 5. PROMPTS MAESTROS INYECTABLES (uso interno o a demanda)

### Exploración de Datos y Limpieza
> "Actúa como Científico de Datos Senior. Tengo un dataset numérico con [N] variables relacionadas a [CONTEXTO]. Genera un script en Python (pandas + seaborn) que: 1) Detecte outliers usando el método IQR y Z-score, 2) Evalúe la normalidad de las variables (Shapiro-Wilk), y 3) Impute valores faltantes usando KNNImputer ajustado SOLO con Train, dentro de un Pipeline de scikit-learn. Aplica el Principio de No Fuga de Datos (Data Leakage)."

### Decisión de Normalización Multimodelo
> "Tengo un vector de datos con distribución asimétrica y outliers extremos. Voy a entrenar un modelo SVM y un Random Forest. Escribe el pipeline en scikit-learn aplicando RobustScaler estrictamente después del train_test_split para el SVM, y sin aplicar escala al Random Forest. Explica matemáticamente tu decisión."

## Contrato de salida

Al entregar un análisis o pipeline, incluye: (1) código ejecutable con el pipeline completo; (2) justificación matemática de cada decisión de preprocesamiento (qué técnica, por qué, qué alternativa se descartó); (3) declaración explícita de dónde ocurre cada `fit` (demostrando ausencia de leakage); (4) métricas con etiquetas de evidencia.

## When to Use

Usa este skill al preparar datasets numéricos/tabulares, elegir o justificar técnicas de normalización e imputación, construir pipelines de scikit-learn, entrenar o evaluar modelos de ML, o auditar código de terceros en busca de Data Leakage. Es complementario del skill `bio-ruiz-hernandez`, que gobierna la redacción científica.

## Limitations

- No sustituye el juicio estadístico: la elección final de técnica depende del diagnóstico del dataset (EDA) y del objetivo del estudio.
- Las reglas de §1 asumen el flujo Train/Test clásico; en series temporales exige splits respetando el orden cronológico (nunca `shuffle=True`).
- Las versiones y límites de librerías (p. ej. TabPFN) cambian; verifica contra la documentación oficial antes de citar cifras en un manuscrito.

---

*Domain adapter of `PROTOCOL.md` v1.5.0 — Canonical DOI: [10.5281/zenodo.21499994](https://doi.org/10.5281/zenodo.21499994)*
