import Foundation

class AKPhoneNumber: AKInputData
{
    override func validate() throws
    {
        do {
            try isReady()
        }
        catch Exceptions.emptyData(let msg) {
            throw Exceptions.emptyData(msg)
        }
        
        guard inputData.characters.count >= GlobalConstants.AKMinPhoneNumberLength else {
            throw Exceptions.invalidLength("El número de teléfono debe tener por lo menos 8 dígitos.")
        }
    }
    
    override func process() throws
    {
        do {
            try isReady()
        }
        catch Exceptions.emptyData(let msg) {
            throw Exceptions.emptyData(msg)
        }
        
        try self.outputData = AKConversions.formatPhoneNumber(phoneNumber: self.inputData, addPrefix: true)
    }
}
