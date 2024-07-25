import SwiftUI
import Firebase

struct FeedbackView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var comment: String = ""
    @State private var showAlert: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var alertMessage: String = ""
    
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
                TextEditor(text: $comment)
                    .frame(height: 200)
            }

            Button(action: submitFeedback) {
                if isSubmitting {
                    ProgressView()
                } else {
                    Text("Submit Feedback")
                }
            }
            .disabled(name.isEmpty || email.isEmpty || age.isEmpty || comment.isEmpty || isSubmitting)
        }
        .navigationBarTitle("Feedback")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Feedback Status"), message: Text(alertMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func submitFeedback() {
        isSubmitting = true
        
        let ref = Database.database().reference()
        let feedbackRef = ref.child("feedback").childByAutoId()
        
        let feedbackData: [String: Any] = [
            "name": name,
            "email": email,
            "age": age,
            "comment": comment,
            "timestamp": ServerValue.timestamp()
        ]
        
        feedbackRef.setValue(feedbackData) { error, _ in
            DispatchQueue.main.async {
                isSubmitting = false
                if let error = error {
                    alertMessage = "Error submitting feedback: \(error.localizedDescription)"
                } else {
                    alertMessage = "Thank you for your feedback!"
                    clearFields()
                }
                showAlert = true
            }
        }
    }
    
    private func clearFields() {
        name = ""
        email = ""
        age = ""
        comment = ""
    }
}


struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            FeedbackView()
        }
        .preferredColorScheme(.dark)
        
        NavigationView {
            FeedbackView()
        }
        .preferredColorScheme(.light)
    }
}
