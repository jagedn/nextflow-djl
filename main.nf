patternURL = 'https://informo.madrid.es/cameras/Camara%s.jpg?v=%d'

camarasList = ["06303","06304","06305","06306","06308",
               "09303","07306","09301","06301","05308","04312",
               "04305","01305","15307","20302","06311",
               "20301"]

urls = camarasList.collect{idx ->
    patternURL.formatted(idx, Math.abs(new Random().nextInt()))
}

process DETECT_OBJECTS{
  input:
    val (url)
  output:
    val objects
  exec:
    objects = ImageDetection.detectObjectsFromURL(url)
}

workflow {

  Channel.fromList(urls)
          | DETECT_OBJECTS
          | flatMap
          | filter { img -> img.probability > 0.6}
          | map { img -> [img.clazz, img]}
          | groupTuple
          | view

}
