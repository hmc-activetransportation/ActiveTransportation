
import UIKit
import MessageUI

class StudentListTableViewController: UITableViewController, MFMailComposeViewControllerDelegate{

    // MARK: Constants
    let ListToUsers = "ListToUsers"
    let ListToContactInfo = "ListToContactInfo"
    let MORNING_PERIOD = "morning"
    let AFTERNOON_PERIOD = "afternoon"
    
    // MARK: Data passed in from segue
    var contactInfoToPass: String!
    var nameToPass: String!
    var busRouteToPass: String!
    var isStaffToPass:Bool!
    var signUpMode = false
    var logExsits = false
    var isMorning = true
    var currentDate : String!
  
    // MARK: Selected student
    var studentSelected: StudentWrapper!
    
    // MARK: Properties
    var studentsWrapper = [String:StudentWrapper]()
    var students = [Student]()
    var keysForTable = [String]()
    var parent:Parent!
    var staff:Staff!
    var meetingInfoBarButtonItem: UIBarButtonItem!
    var isStaff = false
    // Mark: DbCommunicator
    var dbComm = DbCommunicator()

    // MARK: UIViewController Lifecycle
  
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let date = NSDate()
        let calendar:NSCalendar = NSCalendar.currentCalendar()
        let components = calendar.components([.Hour], fromDate: date)
        let hour = components.hour
        if (hour > 0 && hour < 12){
            isMorning = true
        }else{
            isMorning = false
        }

        
        let dateFormatter = NSDateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        self.currentDate =  dateFormatter.stringFromDate(date)
        
        // Set up swipe to delete  
        // TODO what does this have to do with delete?
        tableView.allowsMultipleSelectionDuringEditing = false
        
        // meeting info display
        meetingInfoBarButtonItem = UIBarButtonItem(title: "Meeting Info", style: UIBarButtonItemStyle.Plain, target: self, action: Selector("meetingInfoButtonDidTouch"))
        
        //TODO change font size
        meetingInfoBarButtonItem.tintColor = UIColor.whiteColor()
        navigationItem.leftBarButtonItem = meetingInfoBarButtonItem
        
    }
    
    override func viewDidAppear(animated: Bool) {
        super.viewDidAppear(animated)
        self.authenticateUser()
    }
    
    override func viewDidDisappear(animated: Bool) {
        super.viewDidDisappear(animated)
    }
  
    // MARK: UITableView Delegate methods
    override func tableView(tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return studentsWrapper.count
    }
    
    override func tableView(tableView: UITableView, cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("ItemCell")! as UITableViewCell
        let studentSelected = studentsWrapper[keysForTable[indexPath.row]]
    
        cell.textLabel?.text = studentSelected?.student.name
        cell.detailTextLabel?.text = "Student ID Number: " + (studentSelected?.student.studentID)!
    
        // Determine whether the cell is checked
        toggleCellCheckbox(cell, isCompleted: (studentSelected?.arrived)!)
    
        return cell
    }
  
    override func tableView(tableView: UITableView, canEditRowAtIndexPath indexPath: NSIndexPath) -> Bool {
        return true
    }
    

    override func tableView(tableView: UITableView, editActionsForRowAtIndexPath indexPath: NSIndexPath) -> [UITableViewRowAction]? {
        let more = UITableViewRowAction(style: .Normal, title: "More") { (action, indexPath) in
            self.studentSelected = self.studentsWrapper[self.keysForTable[indexPath.row]]
            self.performSegueWithIdentifier(self.ListToContactInfo, sender: nil)
        }
        
        more.backgroundColor = UIColor.grayColor()
        return [more]
    }
    
    
    override func tableView(tableView: UITableView, didSelectRowAtIndexPath indexPath: NSIndexPath) {
        // Find the cell that user tapped using cellForRowAtIndexPath
        let cell = tableView.cellForRowAtIndexPath(indexPath)!
        // Get the corresponding GreoceryItem by using the index path's row
        let studentSelected = self.studentsWrapper[self.keysForTable[indexPath.row]]

        // Staff Only: Negate completed on the student to toggle the status
        // Only staff has editing access
        if (self.isStaff == true){
            let toggledCompletion = !studentSelected!.arrived
            // Call toggleCellCheckbox() update the visual properties of the cell
            toggleCellCheckbox(cell, isCompleted: toggledCompletion)
            // Passing a dictioary to update Firebase
            studentSelected?.ref!.updateChildValues([studentSelected!.student.studentID: toggledCompletion])
        }
    }
    
    
    func toggleCellCheckbox(cell: UITableViewCell, isCompleted: Bool) {
        if !isCompleted {
            cell.accessoryType = UITableViewCellAccessoryType.None
            cell.textLabel?.textColor = UIColor.blackColor()
            cell.detailTextLabel?.textColor = UIColor.blackColor()
        } else {
            cell.accessoryType = UITableViewCellAccessoryType.Checkmark
            cell.textLabel?.textColor = UIColor.grayColor()
            cell.detailTextLabel?.textColor = UIColor.grayColor()
        }
    }
  
    // MARK: Add Item
    // Button to email page
    @IBAction func emailButtonDidTouch(sender: AnyObject) {
        let mailComposeViewController = configuredMailComposeViewController()
        if MFMailComposeViewController.canSendMail(){
            self.presentViewController(mailComposeViewController, animated: true, completion: nil)
        } else {
            self.showSendMailErrorAlert()
        }
    }
    
    func showSendMailErrorAlert(){
        let sendMailErrorAlert = UIAlertView(title:"Could Not Send Email", message:"Your device could not send e-mail.  Please check e-mail configuration and try again.", delegate: self, cancelButtonTitle: "OK")
            sendMailErrorAlert.show()
    }
    
    func configuredMailComposeViewController() -> MFMailComposeViewController {
        let mailComposerVC = MFMailComposeViewController()
        mailComposerVC.mailComposeDelegate = self
        mailComposerVC.setToRecipients(["someone@somewhere.com"])
        mailComposerVC.setSubject("Active Transportation Bus Route")
        mailComposerVC.setMessageBody("Sending e-mail in-app is not so bad!", isHTML: false)
        
        return mailComposerVC
    }
    
    // MARK: MFMailComposeViewControllerDelegate Method
    func mailComposeController(controller: MFMailComposeViewController!, didFinishWithResult result: MFMailComposeResult, error: NSError!) {
        controller.dismissViewControllerAnimated(true, completion: nil)
    }
  
    func meetingInfoButtonDidTouch() {
        performSegueWithIdentifier(self.ListToUsers, sender: nil)
    }
    
    
    override func prepareForSegue(segue: UIStoryboardSegue, sender: AnyObject!) {
        if (segue.identifier == "ListToUsers") {
            let nav = segue.destinationViewController as! MeetingInfoTableViewController
            nav.isStaff = self.isStaff
            if (self.isStaff == true){
                if (self.staff != nil){
                    nav.staff = self.staff
                    nav.students = self.students
                }
            } else {
                if (self.parent != nil){
                    nav.parent = self.parent
                    nav.students = self.students
                }
            }
        } else if (segue.identifier == "ListToContactInfo") {
            let nav = segue.destinationViewController as! ContactInfoViewController
            if (self.isStaff == true){
                if (self.staff != nil) {
                    nav.isStaff = true
                    nav.studentWprSelected = self.studentSelected
                    nav.staff = self.staff
                }
            }else {
                if (self.parent != nil){
                    nav.isStaff = false
                    nav.studentWprSelected = self.studentSelected
                    nav.parent = self.parent
                }
     
            }
        }
    }

    func authenticateUser(){
        self.dbComm.studentsRef.observeAuthEventWithBlock { authData in
            if authData != nil {
                if (self.signUpMode == true){
                    let currentUserRef = Firebase!(self.dbComm.usersRef.childByAppendingPath(authData.uid))
                    if (self.isStaff){
                        self.staff = Staff(authData:authData, name:self.nameToPass, contactInfo:self.contactInfoToPass,
                            isStaff:true)
                        currentUserRef.setValue(self.staff.toAnyObject())
                    } else {
                        self.parent = Parent(authData:authData, name:self.nameToPass, contactInfo:self.contactInfoToPass,
                            isStaff:false)
                        currentUserRef.setValue(self.parent.toAnyObject())
                    }
                    self.dbComm.studentsRef.unauth()
                    self.reloadTable()
                } else{
                    let idCopy = authData.uid.lowercaseString                    
                    self.dbComm.usersRef.childByAppendingPath(idCopy).observeEventType(.Value, withBlock: { snapshot in
                        if (snapshot.hasChildren()){
                                print (snapshot.value)
                                if (snapshot.value["isStaff"] as! Bool){
                                    self.isStaff = true
                                    self.staff = Staff(uid:snapshot.key as! String,
                                        name:snapshot.value["name"] as! String,
                                        email:snapshot.value["email"] as! String,
                                        contactInfo:snapshot.value["contactInfo"] as! String,
                                        isStaff:snapshot.value["isStaff"] as! Bool,
                                        routeID: snapshot.value["routeID"] as! String)
                                }else{
                                    self.parent = Parent(uid:snapshot.key as! String,
                                        name:snapshot.value["name"] as! String,
                                        email:snapshot.value["email"] as! String,
                                        contactInfo:snapshot.value["contactInfo"] as! String,
                                        isStaff:snapshot.value["isStaff"] as! Bool,
                                        childrenIDs: snapshot.value["childrenIDs"] as! NSDictionary);
                                }
                        }
                            self.loadStudentInfo()
                    })
                    self.dbComm.studentsRef.unauth() // need this to switch between accounts
                    // unauth will not alter or remove the uid of the user
                    
                }
                
            }
        }
    }

    func loadStudentInfo(){
        if(self.isStaff == true){
            self.dbComm.routeRef.childByAppendingPath(self.staff.routeID).observeEventType(.Value, withBlock: {
                snapshot in
                if (snapshot.hasChildren()){
                    let item = BusRoute(snapshot: snapshot as FDataSnapshot)
                    for s in item.students{
                        self.keysForTable.append(s.key as! String)
                        // go find actual student object
                        self.dbComm.studentsRef.childByAppendingPath(s.key as! String).observeEventType(.Value, withBlock: {
                            snapshot2 in
                            if (snapshot2.hasChildren()){
                                print(self.dbComm.studentsRef.childByAppendingPath(s.key as! String))
                                print (snapshot2)
                                let newStudent = Student(snapshot: snapshot2 as FDataSnapshot)
                                let newStudentWpr = StudentWrapper(student: newStudent, arrived: false)
                                self.students.append(newStudent)
                                self.studentsWrapper[newStudent.studentID] = newStudentWpr
                            }
                        })
                        // go find log
                        self.loadStudentArvInfo(s.key as! String);
                    }
                }
            })
        } else{
            self.dbComm.usersRef.childByAppendingPath(self.parent.uid).childByAppendingPath("childrenIDs").observeEventType(.Value,withBlock:{
                snapshot in
                if (snapshot.hasChildren()){
                    let childrenIDs = snapshot.value as! NSDictionary
                    // each child is saved as a ID:name pair in childrenIDs
                    for child in childrenIDs {
                        // save the children's key (studentID) in the keysForTable array
                        // for later display purposes
                        self.keysForTable.append(child.key as! String)
                        // go fetch the actual Student object
                        self.dbComm.studentsRef.childByAppendingPath(child.key as! String).observeEventType(.Value,withBlock:{
                            snapshot2 in
                            if (snapshot2.hasChildren()){
                                let newStudent = Student(snapshot: snapshot2 as FDataSnapshot)
                                let newStudentWpr = StudentWrapper(student:newStudent,arrived:false)
                                self.students.append(newStudent)
                                self.studentsWrapper[newStudent.studentID] = newStudentWpr
                            }
                        })
                        self.loadStudentArvInfo(child.key as! String)
                    }
                }
            })
        }
    }
    
    
    func loadStudentArvInfo(studentID: String){
        var currentLogRef = Firebase()
        if (isMorning == true){
           currentLogRef  = self.dbComm.logRef.childByAppendingPath(self.currentDate).childByAppendingPath(MORNING_PERIOD)
        }else{
            currentLogRef = self.dbComm.logRef.childByAppendingPath(self.currentDate).childByAppendingPath(AFTERNOON_PERIOD)
        }
        
        if (self.isStaff){
            // For staff, create new log records for the day
            currentLogRef.childByAppendingPath(studentID).observeEventType(.Value, withBlock: {
               snapshot in
                self.studentsWrapper[studentID]!.ref = currentLogRef.childByAppendingPath(studentID)
                if (!snapshot.hasChildren()){
                    self.studentsWrapper[studentID]!.ref!.setValue(false)
                    self.studentsWrapper[studentID]!.arrived = false
                }else{
                    self.studentsWrapper[studentID]!.arrived = snapshot.value[studentID] as! Bool
                }
                self.logExsits = true
                self.reloadTable()
            })
        } else {
            currentLogRef.childByAppendingPath(studentID).observeEventType(.Value,withBlock: {
                snapshot in
                if (!snapshot.hasChildren()){
                    self.logExsits = false
                } else {
                    self.studentsWrapper[studentID]!.arrived = snapshot.value[studentID] as! Bool
                }
                self.logExsits = true
                self.reloadTable()
            })
            }
    }
    
    func reloadTable(){
        self.tableView.reloadData()
    }
}




//        // Manually create users.
//        // Manually pushing new user class. Only for testing purposes.
//
//
//                let xiaoyang = ["name":"Xiaoyang Qian", "email":"xqian17@cmc.edu",
//                                                  "contactInfo":"9093446722","isStaff":true,"routeID":"-KF09HvYLPB6oBhffoW2","uid":"31a427d4-9d1a-426a-8497-49b8a73f5230"]
//
//                let userIDRef1 = self.dbComm.usersRef.childByAppendingPath("31a427d4-9d1a-426a-8497-49b8a73f5230")
//                userIDRef1.setValue(xiaoyang)
//
//                let vinhChildrenIDs:NSDictionary = ["-KEz2UzvRd-yp2puQ4Ro":"Xiaoyang_Student1","-KEz2UzvRd-yp2puQ4Rp":"Xiaoyang_Student2","-KEz2UzvRd-yp2puQ4Rq":"Xiaoyang_Student3"]
//                let vinh = ["childrenIDs":vinhChildrenIDs, "name":"Vinh Hoang", "email":"vhoang@hmc.edu",
//                                                  "contactInfo":"1112223333","isStaff":false,"uid":"435879da-a963-4489-9b22-5e2e4b6515ca"]
//                let userIDRef2 = self.dbComm.usersRef.childByAppendingPath("435879da-a963-4489-9b22-5e2e4b6515ca")
//                userIDRef2.setValue(vinh)

//
//        // Manually pushing new routes.
//                let testChildrenList1:NSDictionary = ["-KEz2UzvRd-yp2puQ4Ro":"Xiaoyang_Student1", "-KEz2UzvRd-yp2puQ4Rp":"Xiaoyang_Student2","-KEz2UzvRd-yp2puQ4Rq":"Xiaoyang_Student3"]
//                let testRoute1 = ["meetingLocation":"Mudd Cafe", "meetingTime":"2016-03-30 09:00", "name":"Route1",
//                                  "staffID":"31a427d4-9d1a-426a-8497-49b8a73f5230","students": testChildrenList1]
//
//                let testRoute1Ref = self.dbComm.routeRef.childByAutoId()
//                testRoute1Ref.setValue(testRoute1)

//

// Manually create students.
//                let student1Ref = self.dbComm.studentsRef.childByAutoId()
//                let testStudent1 = ["name":"Xiaoyang_Student1","school":"CMC","parentID":"435879da-a963-4489-9b22-5e2e4b6515ca","routeID":"-KEz6ud-0zlbKaDi6mH-","uid":"-KEz2UzvRd-yp2puQ4Ro"]
//                student1Ref.setValue(testStudent1)
//
//                let student2Ref = self.dbComm.studentsRef.childByAutoId()
//                let testStudent2 = ["name":"Xiaoyang_Student2","school":"CMC","parentID":"435879da-a963-4489-9b22-5e2e4b6515ca","routeID":"-KEz6ud-0zlbKaDi6mH-","uid":"-KEz2UzvRd-yp2puQ4Rp"]
//                student2Ref.setValue(testStudent2)
//
//                let student3Ref = self.dbComm.studentsRef.childByAutoId()
//                let testStudent3 = ["name":"Xiaoyang_Student3","school":"CMC","parentID":"435879da-a963-4489-9b22-5e2e4b6515ca","routeID":"-KEz6ud-0zlbKaDi6mH-","uid":"-KEz2UzvRd-yp2puQ4Rq"]
//                student3Ref.setValue(testStudent3)
//
//                let student4Ref = self.dbComm.studentsRef.childByAutoId()
//                let testStudent4 = ["name":"Vinh_Child1","school":"Mudd","parentID":"435879da-a963-4489-9b22-5e2e4b6515ca","routeID":"-KEz6ud-0zlbKaDi6mH-","uid":"-KEzApViahDjYR1v1ZkF"]
//                student4Ref.setValue(testStudent4)
//
//                let student5Ref = self.dbComm.studentsRef.childByAutoId()
//                let testStudent5 = ["name":"Vinh_Child2","school":"Mudd","parentID":"435879da-a963-4489-9b22-5e2e4b6515ca","routeID":"-KEz6ud-0zlbKaDi6mH-","uid":"-KEzApViahDjYR1v1ZkF"]
//                student5Ref.setValue(testStudent5)


//        // Manually pushing new routes.
//                let testChildrenList1:NSDictionary = ["-KF083fV9L_FzSGTeCXI":"Xiaoyang_Student1", "-KF083fV9L_FzSGTeCXJ":"Xiaoyang_Student2","-KF083fV9L_FzSGTeCXK":"Xiaoyang_Student3"]
//                let testRoute1 = ["meetingLocation":"Mudd Cafe", "meetingTime":"2016-03-30 09:00", "name":"Route1",
//                                  "staffID":"31a427d4-9d1a-426a-8497-49b8a73f5230","students": testChildrenList1]
//
//                let testRoute1Ref = self.dbComm.routeRef.childByAutoId()
//                testRoute1Ref.setValue(testRoute1)
