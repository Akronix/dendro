== Dendro ==
- pasar TZ a UTC y procesar el conjunto total de los datos.
	-> # !! No entiendo porqué treenetproc falla con el daylight saving time incluso con el TZ bien fijado aquí:
	# Pero es desesperante, así que voy a borrar los datos cuando se cambia la hora y palante.
	# Otra opción, forkear y arreglar. El problema está aquí: https://github.com/treenet/treenetproc/blob/6f0fa35df5b2e5e2096dfb0a42512da2163a8213/R/check_input_data.R#L188

- correlacionar temperatura con cambios en crecmiento
- Procesar **todos** los dendrometros
- Mirar también humedad relativa.
