import Foundation

class AKPin: AKInputData
{
    override func validate() throws
    {
        do {
            try isReady()
        }
        catch Exceptions.emptyData(let msg) {
            throw Exceptions.emptyData(msg)
        }
        
        guard inputData.characters.count >= GlobalConstants.AKMinPinLength && inputData.characters.count <= GlobalConstants.AKMaxPinLength else {
            throw Exceptions.invalidLength("El PIN debe tener 4 dígitos.")
        }
    }
}
