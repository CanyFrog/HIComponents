//
//  MultipleViewController.swift
//  HQDownloadDemo
//
//  Created by HonQi on 4/24/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import UIKit
import HQDownload

class MultipleViewController: UIViewController, UICollectionViewDataSource {
    var collectionView: UICollectionView!
    var scheduler = Scheduler([])
    let source = [
        "https://cdn.pixabay.com/photo/2015/06/16/16/46/meadow-811339_1280.jpg",
        "https://cdn.pixabay.com/photo/2018/01/12/10/19/fantasy-3077928_1280.jpg",
        "https://cdn.pixabay.com/photo/2017/10/17/16/10/fantasy-2861107_1280.jpg",
        "https://cdn.pixabay.com/photo/2017/11/07/00/07/fantasy-2925250_1280.jpg",
        "https://cdn.pixabay.com/photo/2017/12/22/11/09/schilthorn-3033448_1280.jpg",
        "https://cdn.pixabay.com/photo/2017/09/16/16/09/sea-2755908_1280.jpg",
        "https://cdn.pixabay.com/photo/2016/11/29/04/19/beach-1867285_1280.jpg",
        "https://cdn.pixabay.com/photo/2018/01/11/19/02/architecture-3076685_1280.jpg",
        "https://cdn.pixabay.com/photo/2018/01/31/12/16/architecture-3121009_1280.jpg",
        "https://cdn.pixabay.com/photo/2017/12/17/19/08/away-3024773_1280.jpg"
    ]
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "多个文件下载"
        let layout = UICollectionViewFlowLayout()
        let width = view.frame.width / 2
        layout.minimumLineSpacing = 0
        layout.minimumInteritemSpacing = 0
        layout.itemSize = CGSize(width: width, height: width)
        collectionView = UICollectionView(frame: view.frame, collectionViewLayout: layout)
        collectionView.backgroundColor = UIColor.white
        collectionView.register(CollectionViewCell.self, forCellWithReuseIdentifier: "Cell")
        collectionView?.dataSource = self

        view.addSubview(collectionView)
        scheduler.subscribe(.completed({ (source, file) in
            print("\n\n Completed \(source.absoluteString) \(file.absoluteString)")
        }))
    }
}

extension MultipleViewController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return source.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        scheduler.download(info: [.sourceUrl(URL(string: source[indexPath.row])!)])?.subscribe(
            .completed({ [weak self] (_, file) in
                let c = self?.collectionView.cellForItem(at: indexPath) as? CollectionViewCell
                c?.setImage(file: file)
            })
        )
        return cell
    }
}

class CollectionViewCell: UICollectionViewCell {
    var imageView = UIImageView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.borderColor = UIColor.white.cgColor
        layer.borderWidth = 1
        backgroundColor = UIColor.gray
        imageView.frame = bounds
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public func setImage(file: URL) {
        imageView.image = UIImage(contentsOfFile: file.path)
    }
}
