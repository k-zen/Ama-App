import Foundation

class AKUsername: AKInputData
{
    override func validate() throws
    {
        do {
            try isReady()
        }
        catch Exceptions.emptyData(let msg) {
            throw Exceptions.emptyData(msg)
        }
        
        guard inputData.characters.count >= GlobalConstants.AKMinUsernameLength else {
            throw Exceptions.invalidLength(String(format: "El nombre de usuario debe tener por lo menos %i caracteres.", GlobalConstants.AKMinUsernameLength))
        }
    }
}
