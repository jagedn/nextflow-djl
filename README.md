# Detecting objects with Nextflow and DJL Machine Learning

Using Machine Learning Object detection to "count objects" in the Madrid's street cameras

## DJL

Deep Java Library (DJL) is an open-source, high-level, engine-agnostic Java framework for deep learning

http://djl.ai/

## Nextflow

Nextflow is a workflow system for creating scalable, portable, and reproducible workflows.

https://www.nextflow.io/docs/latest/index.html

## Apache Groovy

Apache Groovy is a powerful, optionally typed and dynamic language, with static-typing and static compilation capabilities

https://groovy-lang.org/

## Idea

Madrid city publish every 5-10 minutes a serie of images from street cameras. All of them follows same URL
with and ID

For example:

- https://informo.madrid.es/cameras/Camara06303.jpg?v=123123
- https://informo.madrid.es/cameras/Camara01305.jpg?v=123123

(v is a pseudo random number to avoid browser cache, you can use whatever)

We'll use DJL to download and analize all images, detect objects in every one (cars, persons, buses, ...)
and group them by kind, so we'll be able to "count how many cars were detected", for example

## ImageDetection

The core functionality reside in the `ImageDetection.groovy` class:

```
static List<ImageDetected> detectObjects(String url, byte[] imgPath){

    Image img = ImageFactory.instance.fromInputStream(new ByteArrayInputStream(imgPath))

    def criteria = Criteria.builder()
            .optApplication(Application.CV.OBJECT_DETECTION)
            .optFilter("backbone", "resnet50")
            .optEngine(Engine.defaultEngineName)
            .setTypes(Image, DetectedObjects)
            .optArtifactId("ssd")
            .build()

    def model = criteria.loadModel()
    def predictor = model.newPredictor()
    def objects = predictor.predict(img)

    def ret = objects.items().collect {
        new ImageDetected(clazz: it.className, probability: it.probability, url: url)
    }

    ret
}
```

It will convert a byte array to an array of `ImageDetected` objects

## Nextflow Pipeline

The pipeline will be composed by 2 process:

- DOWNLOAD_JPG
- DETECT_OBJECTS

And a main workflow

```
Channel.fromList(urls)
          | DOWNLOAD_JPG
          | DETECT_OBJECTS
          | flatMap
          | filter { ImageDetected img -> img.probability > 0.6}
          | map { ImageDetected img -> [img.clazz, img]}
          | groupTuple
          | view
```

We download all cameras in parallel and, calling ImageDetection function, we obtain ImagedDetected'S so we can
operate with them, filtering, grouping etc

## Nextflow + DJL

In order to use DJL correctly we need instruct Nextflow to include DJL jars in the classpath as DJL requires some
functionally at startup. 

As DJL dependencies are very small I've included them in the `djl` directory so we can include them in the `NXF_CLASSPATH`
environment (or use the `nextflowdjl` file included in the repo)

```
export NXF_CLASSPATH="$(pwd)/djl/api-0.23.0.jar:\
    $(pwd)/djl/commons-compress-1.24.0.jar:\
    $(pwd)/djl/model-zoo-0.23.0.jar:\
    $(pwd)/djl/mxnet-engine-0.23.0.jar:\
    $(pwd)/djl/mxnet-model-zoo-0.23.0.jar:\
    $(pwd)/djl/mxnet-native-auto-1.8.0.jar:\
    $(pwd)/djl/jna-5.13.0.jar" 

./nextflow run main.nf
```

If all goes well you can see a list of ImageDetected

```
Type car:
https://informo.madrid.es/cameras/Camara07306.jpg?v=808436723 0.7579517960548401
https://informo.madrid.es/cameras/Camara09303.jpg?v=149624405 0.8427115082740784
https://informo.madrid.es/cameras/Camara09303.jpg?v=149624405 0.6022432446479797
https://informo.madrid.es/cameras/Camara05308.jpg?v=1581277705 0.983185350894928
https://informo.madrid.es/cameras/Camara05308.jpg?v=1581277705 0.9803544878959656
https://informo.madrid.es/cameras/Camara15307.jpg?v=627005314 0.8596703410148621
https://informo.madrid.es/cameras/Camara15307.jpg?v=627005314 0.8596291542053223
https://informo.madrid.es/cameras/Camara15307.jpg?v=627005314 0.7384243011474609
https://informo.madrid.es/cameras/Camara15307.jpg?v=627005314 0.6458404064178467
https://informo.madrid.es/cameras/Camara04312.jpg?v=1322937729 0.7195010185241699

Type bus:
https://informo.madrid.es/cameras/Camara06308.jpg?v=728523069 0.6699512004852295
https://informo.madrid.es/cameras/Camara20301.jpg?v=626577852 0.7132446765899658

Type motorbike:
https://informo.madrid.es/cameras/Camara06308.jpg?v=728523069 0.787713885307312

```


## Examples

![Example1](example.png?raw=true "Example 1")

![Example](example2.png?raw=true "Example 2")

![Example](example3.png?raw=true "Example 3")
