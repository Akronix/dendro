== Dendro ==
- Cargar datos Corvalán y mirar si llegan a -10ºC y ver qué pasa con las congelaciones/descongelaciones.
- Hacer encargo gráfica antonio gazol para septiembre-23. Mirar también que pasa con QI después de sept-23 con última descarga de datos.
Análisis:
	- Ver cómo correlaciona con la humedad. Ver por separado D y NDs.
	- Contrastar hipótesis y conclusiones de paper Cristina; y también comprobar periodos de crecimiento con Alice.
- sacar funciones útiles y repetidasa a fichero lib.R externo. Refactor del código. Hacer función para cargar ficheros uno a uno en lugar de unir todos juntos.
- mejorar treenetproc:
	* permitir poner nombre al plot salida de `corr_dendro_L2()`
	* permitir hacer force jump pero en la fecha indicada y no cuando quiera treenetproc
	* que detecte también largos valores ctes y los borre.
	* permitir sacar output como plot de R para ggplot y no solo como pdf.
