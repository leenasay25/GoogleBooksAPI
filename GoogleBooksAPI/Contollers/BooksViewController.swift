//
//  BooksViewController.swift
//  GoogleBooksAPI-
//
//  Created by Leena Alsayari on 7/3/23.
//

import UIKit
import CoreData

class BookViewController: UIViewController, UITableViewDelegate, UITableViewDataSource, UISearchBarDelegate, NSFetchedResultsControllerDelegate {
    
    //Table View Variables
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var indicator: UIActivityIndicatorView!
    
    var books = [Book]()
    var booksURLs : String = ""
    //Search Bar Variables
    @IBOutlet weak var searchBar: UISearchBar!
    var filteringIsOn: Bool = false
    var searchTerm: String = "" {
        didSet {
            if searchTerm == "" {
                filteringIsOn = false
            } else {
                filteringIsOn = true
            }
            
            loadData()
        }
    }
    
    var dataController:DataController!
    var fetchedResultsController:NSFetchedResultsController<FavBook>!
    
    private var didTapDeleteKey = false
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        self.title = "Book Library"
        indicator.isHidden = true
        loadData()
        tableView.delegate = self
        tableView.dataSource = self
        searchBar.delegate = self
    }
    
    
    func showAlert(error: AppError){
        let alert = UIAlertController(title: "Error", message: error.localizedDescription, preferredStyle: UIAlertController.Style.alert)
        alert.addAction(UIAlertAction(title: "ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
        
    }
    
    func loadData() {
        
        let urlString = (!filteringIsOn) ? ("https://www.googleapis.com/books/v1/volumes?q=Pratchett") : ("https://www.googleapis.com/books/v1/volumes?q=\(searchTerm)&maxResults=40")
        
        BookAPIClient.manager.getBooks(
            from: urlString,
            completionHandler: { (onlineBooks) in
                DispatchQueue.main.async { [self] in
                    self.books = onlineBooks
                    self.tableView.reloadData()
                }
            },
            errorHandler: { (error: AppError) -> Void in
                DispatchQueue.main.async {
                    self.showAlert(error: error)
                }
            })
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
    }
    
    
    //Table View Methods
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let cell = tableView.cellForRow(at: indexPath)
        performSegue(withIdentifier: "detailedSegue", sender: cell)
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 60
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return books.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "bookCell", for: indexPath) as! bookCell
        let currentBook = books[indexPath.row]
        
        let title = currentBook.volumeInfo.title
        let subtitle = currentBook.volumeInfo.subtitle
        
        cell.title?.text = title
        cell.subtitle?.text = subtitle
        //resets the image before you set it to the next one - should help with flickering
        cell.imageView?.image = nil
        
        guard let imageURLString = currentBook.volumeInfo.imageLinks?.thumbnail else {
            return cell
        }
        
        
        ImageAPIClient.manager.getImage(
            from: imageURLString,
            completionHandler: { (onlineImage) in
                DispatchQueue.main.async {
                    self.indicator.isHidden = false
                    self.indicator.startAnimating()
                    cell.imageView?.image = onlineImage
                    cell.setNeedsLayout()
                }
            },
            errorHandler: { (error) in
                switch error {
                case .badURL:
                    print("bad url")
                default:
                    print("other error")
                }
            })
        self.indicator.stopAnimating()
        self.indicator.isHidden = true
        cell.selectionStyle = UITableViewCell.SelectionStyle.none
        cell.layer.borderWidth = 1.0
        cell.layer.borderColor = UIColor.black.cgColor
        return cell
    }
    
    
    //Search Bar Methods
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        guard let searchText = searchBar.text else {
            return
        }
        
        searchTerm = searchText
    }
    
    
    func searchBar(_ searchBar: UISearchBar,
                   shouldChangeTextIn range: NSRange,
                   replacementText text: String) -> Bool
    {
        didTapDeleteKey = text.isEmpty
        
        return true
    }
    
    func searchBar(_ searchBar: UISearchBar,
                   textDidChange searchText: String)
    {
        if !didTapDeleteKey && searchText.isEmpty {
            searchTerm=""
            loadData()
        }
        
        didTapDeleteKey = false
    }
    
    //Navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if let destinationVC = segue.destination as? BookDetailViewController, let cell = sender as? UITableViewCell, let currentIndexPath = tableView.indexPath(for: cell) {
            let currentBook = books[currentIndexPath.row]
            destinationVC.book = currentBook
            destinationVC.dataController = dataController
        }
        
    }
    
    
}
