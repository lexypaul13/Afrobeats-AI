import SwiftUI
import Firebase



struct FeedbackView: View {
    @State private var name: String = ""
    @State private var email: String = ""
    @State private var age: String = ""
    @State private var comment: String = ""
    @State private var showAlert: Bool = false
    @State private var isSubmitting: Bool = false
    @State private var debugMessage: String = ""
    
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

            Button(action: {
                debugMessage = "Button tapped at \(Date())"
                submitFeedback()
            }) {
                Text("Submit Feedback")
            }
            .disabled(name.isEmpty || email.isEmpty || age.isEmpty || comment.isEmpty || isSubmitting)

            if !debugMessage.isEmpty {
                Text(debugMessage)
                    .font(.footnote)
                    .foregroundColor(.secondary)
            }
        }
        .navigationBarTitle("Feedback")
        .alert(isPresented: $showAlert) {
            Alert(title: Text("Feedback Status"), message: Text(debugMessage), dismissButton: .default(Text("OK")))
        }
    }

    private func submitFeedback() {
        isSubmitting = true
        debugMessage += "\nSubmission started"
        
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
                    debugMessage += "\nError: \(error.localizedDescription)"
                } else {
                    debugMessage += "\nSubmission completed successfully"
                    // Clear fields
                    name = ""
                    email = ""
                    age = ""
                    comment = ""
                }
                showAlert = true
            }
        }
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
