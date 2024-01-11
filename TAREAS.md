== Dendro ==

- Poner var globales de tol_out y tol_jump al comienzo de process_dendro.R

- Hacer medias de datos ambientales.

- Sacar valores de humedad a partir de datos TDT de TOMST haciendo la conversión. Comprobar fiabilidad paquete R contrastado con macros.  Hacer paquete nuevo de R solo para esto? o meterlo en mi lib-dendro?

- procesar todos datos de Corvalán y peñaflor. Mejorar automatización en procesado de datos.

- normalizar datos dendros Partinchas a rango 0-1 para su comparación?

= Análisis =
(Centrarse en periodo de crecimiento definido en paper Cristina) -> De Abril a Octubre ? (Comprobar con paper)
	- Repasar apuntes y aplicar análisis.
	- Ver cómo correlaciona con la humedad y precipitación. Ver por separado D y NDs.
	- Contrastar hipótesis y conclusiones de paper Cristina; y también comprobar periodos de crecimiento con Alice.
	
- mejorar treenetproc:
	* Qué hace el reverse a jumps del corr_dendro_L2 que muchas veces no deja los datos a como estarían sin ser tocado?? (ejemplo con dendro 92222157)
	* permitir poner nombre al plot salida de `corr_dendro_L2()`
	* permitir hacer force jump pero en la fecha indicada y no cuando quiera treenetproc
	* que detecte también largos valores ctes y los borre.
	* permitir sacar output como plot de R para ggplot y no solo como pdf.
	* mejorar la detección de saltos de alguna manera...incorporar modelo de crecimiento o machine learning?
	
