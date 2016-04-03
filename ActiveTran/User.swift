
import Foundation

class User {
  let uid: String
  let name: String
  let email: String
  let contactInfo: String
  let isStaff: Bool!
  
 
  // Initialize from Firebase
    init(authData: FAuthData, name:String, contactInfo: String, isStaff: Bool) {
    self.uid = authData.uid.lowercaseString
    self.name = name
    self.email = authData.providerData["email"] as! String
    self.contactInfo = contactInfo
    self.isStaff = isStaff 
   // self.childrenIDs = childrenIDs
  }
    
    init(snapshot: FDataSnapshot) {
        uid = snapshot.value["uid"] as! String
        name = snapshot.value["name"] as! String
        email = snapshot.value["email"] as! String
        contactInfo = snapshot.value["contactInfo"] as! String
        isStaff = snapshot.value["isStaff"] as! Bool
        
    }
  
  // Initialize from arbitrary data
    init(uid: String, name: String, email: String, contactInfo: String, isStaff: Bool) {
    self.uid = uid
    self.name = name
    self.email = email
    self.contactInfo = contactInfo
    self.isStaff = isStaff
  }
    
    func toAnyObject() -> AnyObject {
    return[
    "uid": uid,
    "name": name,
    "email": email,
    "contactInfo": contactInfo,
    "isStaff": isStaff,
    ]
    }
}
