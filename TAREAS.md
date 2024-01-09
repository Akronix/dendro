== Dendro ==
- arreglar read.one.dendro de lib-dendro.R para que se cargue con el nombre del dendro seleccionado
- pasar función de leer datos env de analysis-dendro.Rmd a lib-dendro.R

- procesar todos datos de Corvalán y peñaflor. Mejorar automatización en procesado de datos.

- Sacar valores de humedad a partir de datos TDT de TOMST haciendo la conversión. Comprobar fiabilidad paquete R contrastado con macros.

- Mirar también que pasa con QI después de sept-23 con última descarga de datos.

= Análisis =
(Centrarse en periodo de crecimiento definido en paper Cristina) -> De Abril a Octubre ? (Comprobar con paper)
	- Repasar apuntes y aplicar análisis.
	- Ver cómo correlaciona con la humedad y precipitación. Ver por separado D y NDs.
	- Contrastar hipótesis y conclusiones de paper Cristina; y también comprobar periodos de crecimiento con Alice.
- sacar funciones útiles y repetidasa a fichero lib.R externo. Refactor del código. Hacer función para cargar ficheros uno a uno en lugar de unir todos juntos.
- mejorar treenetproc:
	* permitir poner nombre al plot salida de `corr_dendro_L2()`
	* permitir hacer force jump pero en la fecha indicada y no cuando quiera treenetproc
	* que detecte también largos valores ctes y los borre.
	* permitir sacar output como plot de R para ggplot y no solo como pdf.
	
