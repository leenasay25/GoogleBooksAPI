//
//  BookDetailViewController.swift
//  GoogleBooksAPI
//
//  Copyright © 2017 Melissa He @ C4Q. All rights reserved.
//

import UIKit

class BookDetailViewController: UIViewController {
    
    @IBOutlet weak var bookImageView: UIImageView!
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var subtitleLabel: UILabel!
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var descriptionTextView: UITextView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var book: Book!
    var dataController:DataController!
    var imageData : Data? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUpUI()
    }
    
    func showAlert(error: AppError){
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
    func setUpUI() {
        titleLabel.text = book.volumeInfo.title
        subtitleLabel.text = book.volumeInfo.subtitle ?? "No Subtitle Available"
        authorLabel.text = book.volumeInfo.authors?.joined(separator: ", ") ?? "No authors available"
        descriptionTextView.text = book.volumeInfo.description ?? "No description available"
        setUpImages()
    }
    
    func setUpImages() {
        guard let imageURLString = book.volumeInfo.imageLinks?.thumbnail else {
            return
        }
        
        ImageAPIClient.manager.getImage(
            from: imageURLString,
            completionHandler: { (onlineImage) in
                DispatchQueue.main.async {
                    self.indicator.isHidden = false
                    self.indicator.startAnimating()
                    self.bookImageView.image = onlineImage
                    self.imageData = onlineImage.jpegData(compressionQuality: 1.0)
                }
        },
            errorHandler: { (error) in
                self.showAlert(error: error)
                })
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    @IBAction func favButtonTapped(_ sender: Any) {
        let favBook = FavBook(context: dataController.viewContext)

        
        favBook.title  = book.volumeInfo.title
        
        favBook.subtitle = book.volumeInfo.subtitle ?? "No Subtitle Available"
        favBook.author =  book.volumeInfo.authors?.joined(separator: ", ") ?? "No authors available"
        favBook.image = imageData
        do {
            try dataController.viewContext.save()
        }catch {
            print(error.localizedDescription)
        }
                let FavViewController = self.storyboard!.instantiateViewController(withIdentifier: "FavViewController") as! FavViewController
                FavViewController.dataController = dataController
               
    }
}
