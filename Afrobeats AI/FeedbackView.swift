import SwiftUI
import Firebase

struct FeedbackView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var comment: String = ""
    @State private var showAlert: Bool = false
    var body: some View {
        Form {
            Section(header: Text("Your Details")) {
                TextField("Name", text: $name)
                TextField("Email", text: $email)
                    .keyboardType(.emailAddress)
                TextField("Age", text: $age)
                    .keyboardType(.numberPad)
            }

            Section(header: Text("Your Feedback")) {
                 ZStack(alignment: .topLeading) {
                     if comment.isEmpty {
                         Text("Your feedback is invaluable! Let us know what enhancements and features you'd like to see in the full version.")
                             .foregroundColor(.gray)
                             .padding(.vertical, 8)
                             .padding(.horizontal, 4)
                     }
                     TextEditor(text: $comment)
                         .frame(height: 200)
                 }
             }

            Button("Submit Feedback", action: submitFeedback)
                .disabled(name.isEmpty || email.isEmpty || age.isEmpty || comment.isEmpty)
                .alert(isPresented: $showAlert) {
                    Alert(title: Text("Thank You!"), message: Text("Thank you for your feedback"), dismissButton: .default(Text("OK")))
                }
        }
        .navigationBarTitle("Feedback")
    }

    private func submitFeedback() {
        // Reference to the database
        let ref = Database.database().reference()
        
        // Create a unique child node under 'feedback' node
        let feedbackRef = ref.child("feedback").childByAutoId()
        
        // Data to be pushed
        let feedbackData: [String: Any] = [
            "name": name,
            "email": email,
            "age": age,
            "comment": comment,
            "timestamp": ServerValue.timestamp()
        ]
        
        // Push data to Firebase Realtime Database
        feedbackRef.setValue(feedbackData) { error, _ in
            if let error = error {
                print("Data could not be saved: \(error)")
            } else {
                // Show thank you message
                showAlert = true

                // Clear the fields after submission
                name = ""
                email = ""
                age = ""
                comment = ""
            }
        }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
    }
}
