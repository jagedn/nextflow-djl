import ai.djl.Application
import ai.djl.engine.Engine
import ai.djl.modality.cv.Image
import ai.djl.modality.cv.ImageFactory
import ai.djl.modality.cv.output.DetectedObjects
import ai.djl.repository.zoo.Criteria

class ImageDetection {

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
}
