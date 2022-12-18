//
//  NewsVC.swift
//  ForPDA
//
//  Created by Subvert on 04.12.2022.
//

import UIKit
import SwiftSoup
import Nuke
import SwiftMessages

final class NewsVC: PDAViewController<NewsView> {
    
    let host = "https://4pda.to/"
    
    var articles = [Article]()

    override func viewDidLoad() {
        super.viewDidLoad()
        
        myView.tableView.delegate = self
        myView.tableView.dataSource = self
        
        setupLongPressGesture()
        
        getSite()
//        URLSession.shared.dataTask(with: URLRequest(url: URL(string: "https://habr.com/ru/news/t/706174/")!)) { data, response, error in
//            let htmlString = String(data: data!, encoding: .utf8)!
//            let parsed = try! SwiftSoup.parse(htmlString)
//            print(parsed)
//        }.resume()
    }
    
    private func getSite() {
        URLSession.shared.dataTask(with: URLRequest(url: URL(string: host)!)) { data, response, error in

            let htmlString = String(data: data!, encoding: .windowsCP1252)!
            let parsed = try! SwiftSoup.parse(htmlString)
            
            let articles = try! parsed.select("article")
            for (_, article) in articles.enumerated() {
                // first three may be an advertisement
                // guard (3...).contains(index) else { continue }
                let type = try! article.attr("class")
                //print("TTYPE \(type)")
                if type.components(separatedBy: " ").count == 3 { continue } // paid post not supported yet
                
                //print("\n\(index) ----------------------------------------------------------------------")
                //print(article.description.converted())
                let title = try! article.select("[itemprop=name]").text()
                
                guard !title.isEmpty else { continue }
                
                let url = try! article.select("[rel=bookmark]").attr("href")
                let description = try! article.select("[itemprop=description]").text()
                let imageUrl = try! article.select("img").get(0).attr("src")
                let author = try! article.select("[class=autor]").select("a").text()
                let date = try! article.select("[class=date]").text()
                let commentAmount = try! article.select("[class=v-count]").text()
                
                let article = Article(url: url,
                                      title: title.converted(),
                                      description: description.converted(),
                                      imageUrl: imageUrl,
                                      author: author.converted(),
                                      date: date,
                                      commentAmount: commentAmount)
                
                // print(article)
                self.articles.append(article)
            }
            
            DispatchQueue.main.async {
                self.myView.tableView.reloadData()
            }
            
        }.resume()
    }
    
    func setupLongPressGesture() {
        let longPressGesture = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(_:)))
        longPressGesture.minimumPressDuration = 1.0
        // longPressGesture.delegate = self
        myView.addGestureRecognizer(longPressGesture)
    }

    @objc func handleLongPress(_ gestureRecognizer: UILongPressGestureRecognizer) {
        if gestureRecognizer.state == .began {
            let touchPoint = gestureRecognizer.location(in: myView.tableView)
            if let indexPath = myView.tableView.indexPathForRow(at: touchPoint) {
                UIPasteboard.general.string = articles[indexPath.row].url

                SwiftMessages.show {
                    let view = MessageView.viewFromNib(layout: .centeredView)
                    view.configureTheme(.success)
                    view.configureDropShadow()
                    view.configureContent(title: "Скопировано", body: self.articles[indexPath.row].url)
                    (view.backgroundView as? CornerRoundingView)?.cornerRadius = 10
                    view.button?.isHidden = true
                    return view
                }
            }
        }
    }
}

extension NewsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return articles.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: ArticleCell.reuseIdentifier, for: indexPath) as! ArticleCell
        cell.set(article: articles[indexPath.row])
        return cell
    }
    
    func scrollViewWillBeginDecelerating(_ scrollView: UIScrollView) {
       if scrollView.panGestureRecognizer.translation(in: scrollView).y < 0 {
          navigationController?.setNavigationBarHidden(true, animated: true)
       } else {
          navigationController?.setNavigationBarHidden(false, animated: true)
       }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        let vc = ArticleVC(article: articles[indexPath.row])
//        let vc = CommentsVC()
//        vc.article = articles[indexPath.row]
        navigationController?.setNavigationBarHidden(false, animated: false)
        navigationController?.pushViewController(vc, animated: false)
    }
}
