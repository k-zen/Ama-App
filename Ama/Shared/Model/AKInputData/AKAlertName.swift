import Foundation

class AKAlertName: AKInputData {
    override func validate() throws {
        do {
            try isReady()
        }
        catch Exceptions.emptyData(let msg) {
            throw Exceptions.emptyData(msg)
        }
        
        guard inputData.characters.count >= GlobalConstants.AKMinAlertNameLength else {
            throw Exceptions.invalidLength(String(format: "El nombre de las alertas debe tener por lo menos %i caracteres.", GlobalConstants.AKMinAlertNameLength))
        }
    }
}
