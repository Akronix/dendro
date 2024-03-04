== Dendro ==

- tunear ccf para que: i) no use lags negativos, ii) Use método spearman. Estudiar significación de lags, para ver si se puede deducir que hay correlación con lags de varios días (es decir, una lluvia afecta durante los próximos x número de días al árbol)

- Hacer forcejump justo en la fecha que se diga en treenetproc y procesar dendrómetro 92222178. Mejorar automatización en procesado de datos?

- Hacer script para Corbalán y Peñaflor también.

- Generar de nuevo datos myClim para Corbalán y Peñaflor.

- Ver cuánto cambia medias de vwc con sensores de valores en NA y sin ellos. Mirar mejor solución: Imputación de datos microclima ? o solo los que sí tienen valores?

- Comenzar a escribir paper.

- correlaciones y wavelets.

- regresiones / modelización con modelos mixtos

- Sacar valores de humedad a partir de datos TDT de TOMST haciendo la conversión. Comprobar fiabilidad paquete R contrastado con macros. Hacer paquete nuevo de R solo para esto? o meterlo en mi lib-dendro? -> Creo que es necesario que leas el paper de calibración de TOMST para ver cómo va todo este tema de la calibración. -> esperando respuesta de Martin my Clim. -> Comprobar correo Martin!!

= Análisis =

1) Sacar patrones diario, mensual y estacional de hinchamiento y deshinchamiento de cada especie y clase (TS decomposition)

2) Hacer correlaciones con humedad y temperatura. Generar modelo mixto. Explorar sensibilidad a CP (en tendencia) de las diferentes especies.

4) Sacar variables de crecimiento y ligar a especies y clases.

- inspeccionar campanas procesamiento Corbalan y Peñaflor vs clima y humedad.

(Centrarse en periodo de crecimiento definido en paper Cristina) -> De Abril a Octubre ? (Comprobar con paper)
	- Repasar apuntes y aplicar análisis.
	- Ver cómo correlaciona con la humedad y precipitación. Ver por separado D y NDs.
	- Contrastar hipótesis y conclusiones de paper Cristina; y también comprobar periodos de crecimiento con Alice.
	
- mejorar treenetproc:
	* permitir hacer force jump pero en la fecha indicada y no cuando quiera treenetproc -> El force jump tiene algo raro que pilla la posición 2 horas después (u 8 valores después) de la diferencia máxima.
	* Qué hace el reverse a jumps del corr_dendro_L2 que muchas veces no deja los datos a como estarían sin ser tocado?? (ejemplo con dendro 92222157)
	* que detecte también largos valores ctes y los borre.
	* permitir sacar output como plot de R para ggplot y no solo como pdf.
	* mejorar la detección de saltos de alguna manera...incorporar modelo de crecimiento o machine learning?
	* ¿Por qué poniendo tol_out o tol_jump a 1000 sigue pillando outliers??? Ver ejemplo con sensores 92232428, 92232435 y dendro 92232430 de Valcuerna
	* opción para deshacer todos los cambios hechos por `proc_dendro_L2`
	* Calcular TWD y GRO en un subintervalo de los datos (redefiniendo, por tanto, el punto de referencia 0 de los datos).
		
	
