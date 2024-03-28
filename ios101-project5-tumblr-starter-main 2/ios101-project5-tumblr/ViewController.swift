import UIKit

class ViewController: UIViewController, UITableViewDataSource {
    
    // Property to store fetched posts array
    private var posts: [Post] = []
    
    @IBOutlet weak var tableView: UITableView! // Add table view outlet
    
    // Method to refresh data
    @objc func refreshData(_ sender: Any) {
        fetchPosts()
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Set dataSource of tableView
        tableView.dataSource = self
        
        // Create refresh control
        let refreshControl = UIRefreshControl()
        refreshControl.addTarget(self, action: #selector(refreshData(_:)), for: .valueChanged)
        
        // Configure Refresh Control
        refreshControl.tintColor = UIColor.gray
        refreshControl.attributedTitle = NSAttributedString(string: "Refreshing...")
                
        // Attach Refresh Control to Table View
        tableView.refreshControl = refreshControl

        fetchPosts() // Fetch posts
    }

    // Fetches a list of blog posts from the Tumblr API
    func fetchPosts() {
        // URL for retrieving published posts
        guard let url = URL(string: "https://api.tumblr.com/v2/blog/hungoverowls/posts/photo?api_key=1zT8CiXGXFcQDyMFG7RtcfGLwTdDjFUJnZzKJaWTmgyK4lKGYk") else {
            print("❌ Error: Invalid URL")
            return
        }
        
        // Create URLSession to execute network request
        let session = URLSession.shared.dataTask(with: url) { [weak self] data, response, error in
            if let error = error {
                print("❌ Error: \(error.localizedDescription)")
                return
            }
            
            // Check for server errors
            guard let httpResponse = response as? HTTPURLResponse, (200...299).contains(httpResponse.statusCode) else {
                print("❌ Response error: \(String(describing: response))")
                return
            }
            
            // Check for data
            guard let data = data else {
                print("❌ Data is NIL")
                return
            }
            
            // Decode JSON data into custom Blog model
            do {
                let blog = try JSONDecoder().decode(Blog.self, from: data)
                let posts = blog.response.posts

                DispatchQueue.main.async {
                    self?.posts = posts
                    self?.tableView.reloadData()
                    self?.tableView.refreshControl?.endRefreshing()
                }

            } catch {
                print("❌ Error decoding JSON: \(error.localizedDescription)")
            }
        }
        session.resume()
    }
    
    // Method to return number of rows in table view
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return posts.count
    }
    // Method to configure and return a table view cell
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "BlogCell", for: indexPath) as! BlogCell
        let post = posts[indexPath.row]
        
        // Clear the imageView in case there's a reusable cell
        cell.posterImageView.image = nil
        
        // Load image asynchronously if post has photos
        if let photo = post.photos.first {
            let urlString = photo.originalSize.url.absoluteString
            if let url = URL(string: urlString) {
                    let task = URLSession.shared.dataTask(with: url) { [weak cell] data, response, error in
                        guard let data = data, error == nil else { return }
                        DispatchQueue.main.async {
                            if let image = UIImage(data: data) {
                                cell?.posterImageView.image = image
                            }
                        }
                    }
                    task.resume()
                }
            }
            // Set post's summary for the title
            cell.titleLabel.text = post.summary
            
            return cell
        }

}

