//
//  MultipleCacheViewController.swift
//  HQDownloadDemo
//
//  Created by Magee Huang on 7/27/18.
//  Copyright © 2018 HonQi Indie. All rights reserved.
//

import UIKit
import HQDownload

class MultipleCacheViewController: UIViewController, UICollectionViewDataSource {

    var collectionView: UICollectionView!
    var downloader = Downloader([])
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
        title = "多个文件缓存下载"
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
        downloader.subscribe(.completed({ [weak self] (url, file) in
            let str = url.absoluteString
            let idx = self?.source.index(of: str)
            let cell = self?.collectionView.cellForItem(at: IndexPath(row: idx!, section: 0)) as? CollectionViewCell
            cell?.setImage(file: file)
        }))
    }
}

extension MultipleCacheViewController {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return source.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "Cell", for: indexPath) as! CollectionViewCell
        downloader.download(source: source[indexPath.row])
        return cell
    }
}
