== Dendro ==

- Por qué c**** sigue apareciendo el saltito de junio en las medias????? -> Tiene que ser algún dendro que he revertido su procesamiento... (p.ej. volver a mirar 92232434) -> No. Es simplemente fecha que se ha hecho algo raro sobre el terreno / campo.

- tratar datos ambientales. gráficas de líneas de humedad, una por sensor.

- Hacer medias de datos ambientales. -> Hacer antes gráfica de humedad para distintos sensores.

- Sacar valores de humedad a partir de datos TDT de TOMST haciendo la conversión. Comprobar fiabilidad paquete R contrastado con macros.  Hacer paquete nuevo de R solo para esto? o meterlo en mi lib-dendro? -> Creo que es necesario que leas el paper de calibración de TOMST para ver cómo va todo este tema de la calibración.

- procesar todos datos de Corvalán y peñaflor. Mejorar automatización en procesado de datos.

- Terminar análisis descriptivo datos.

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
	* ¿Por qué poniendo tol_out o tol_jump a 1000 sigue pillando outliers??? Ver ejemplo con sensores 92232428, 92232435 y dendro 92232430 de Valcuerna
	* opción para deshacer todos los cambios hechos por `proc_dendro_L2`
	
	
