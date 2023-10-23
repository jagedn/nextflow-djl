import nextflow.io.ValueObject as ValueObject

@ValueObject
class ImageDetected {
        String clazz
        double probability
        String url
}
