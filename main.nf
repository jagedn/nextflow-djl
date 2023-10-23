patternURL = 'https://informo.madrid.es/cameras/Camara%s.jpg?v=%d'

camarasList = ["06303","06304","06305","06306","06308",
               "09303","07306","09301","06301","05308","04312",
               "04305","01305","15307","20302","06311",
               "20301"]

urls = camarasList.collect{idx ->
    patternURL.formatted(idx, Math.abs(new Random().nextInt()))
}


process DOWNLOAD_JPG{
  input:
    val url
  output:
    tuple val(url), val(image)
  exec:
    image = "$url".toURL().bytes
}

process DETECT_OBJECTS{
  input:
  tuple val(url), val(image)
  output:
    val objects
  exec:
    objects = ImageDetection.detectObjects(url, image)
}

workflow {

  Channel.fromList(urls)
          | DOWNLOAD_JPG
          | DETECT_OBJECTS
          | flatMap
          | filter { ImageDetected img -> img.probability > 0.6}
          | map { ImageDetected img -> [img.clazz, img]}
          | groupTuple
          | view { tuple ->
            println "Type ${tuple[0]}:"
            tuple[1].each{
              println "$it.url $it.probability"
            }
          }


}
