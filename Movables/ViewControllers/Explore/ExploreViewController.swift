//
//  ExploreViewController.swift
//  Movables
//
//  MIT License
//
//  Copyright (c) 2018 Eddie Chen
//
//  Permission is hereby granted, free of charge, to any person obtaining a copy
//  of this software and associated documentation files (the "Software"), to deal
//  in the Software without restriction, including without limitation the rights
//  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
//  copies of the Software, and to permit persons to whom the Software is
//  furnished to do so, subject to the following conditions:
//
//  The above copyright notice and this permission notice shall be included in all
//  copies or substantial portions of the Software.
//
//  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
//  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
//  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
//  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
//  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
//  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
//  SOFTWARE.

import UIKit
import MapKit
import InstantSearchClient

protocol ExploreViewControllerDelegate: class {
    func showPackageDetail(with package: Package)
}

class ExploreViewController: UIViewController {
    
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var cardPeekCollectionView: UICollectionView!
    
    var togglesCollectionView: UICollectionView!
    var topicsTrendingCollectionView: UICollectionView!
    
    let apiClient = Client(appID: (UIApplication.shared.delegate as! AppDelegate).algoliaClientId!, apiKey: (UIApplication.shared.delegate as! AppDelegate).algoliaAPIKey!)
    
    var packages: [Package] = []
    
    var annotations: [PackageAnnotation] = []
    var coordinateToAnnotations: [CLLocationCoordinate2D: [PackageAnnotation]]?
    var coordinateToNewAnnotations: [CLLocationCoordinate2D: [PackageAnnotation]] = [:]
    var modifiedAnnotations: [PackageAnnotation] = []
    
    var topics: [TopicResultItem] = []
    
    var delegate: ExploreViewControllerDelegate?
    
    var topicName: String? {
        didSet {
            fetchNearbyPackages()
        }
    }
    
    var selectedTopicIndex: IndexPath?
    
    var category: PackageCategory? {
        didSet{
            fetchNearbyPackages()
        }
    }
    var sortBy: SortBy = .distance
    var status: PackageStatus?
    
    
    private var indexOfCellBeforeDragging = 0
    private var collectionViewFlowLayout: UICollectionViewFlowLayout = UICollectionViewFlowLayout.init()
    
    var initialFetchMade = false
    var collectionViewHeightConstraint: NSLayoutConstraint!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        navigationController?.setNavigationBarHidden(true, animated: false)
        
        setupLocationManager()
        setupMapView()
        setupTopicsTrendingCollectionView()
        setupToggleCollectionView()
        setupCollectionView()
        fetchTopics()        
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        configureCollectionViewLayoutItemSize()
    }
    
    func calculateSectionInset() -> CGFloat {
        return 30
    }
    
    private func configureCollectionViewLayoutItemSize() {
        let inset: CGFloat = calculateSectionInset()
        collectionViewFlowLayout.sectionInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset - 16)
        
        collectionViewFlowLayout.itemSize = UICollectionViewFlowLayout.automaticSize
        collectionViewFlowLayout.estimatedItemSize = CGSize(width: view.safeAreaLayoutGuide.layoutFrame.width - inset * 2, height: cardPeekCollectionView.frame.height)
    }
    
    private func indexOfMajorCell() -> Int {
        let itemWidth = collectionViewFlowLayout.estimatedItemSize.width
        let proportionalOffset = collectionViewFlowLayout.collectionView!.contentOffset.x / itemWidth
        return Int(round(proportionalOffset))
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func setupLocationManager() {
        let locationManager = LocationManager.shared
        locationManager.requestWhenInUseAuthorization()
        LocationManager.shared.desiredAccuracy = kCLLocationAccuracyHundredMeters
        LocationManager.shared.startUpdatingLocation()
        locationManager.delegate = self
        
    }
    
    func setupMapView() {
        fetchNearbyPackages()
        mapView.tintColor = Theme().keyTint
        mapView.isRotateEnabled = false
        mapView.showsUserLocation = true
        mapView.mapType = .mutedStandard
        mapView.showsPointsOfInterest = false
        mapView.delegate = self
        mapView.register(MKMarkerAnnotationView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier)
        mapView.register(PackagesClusterView.self, forAnnotationViewWithReuseIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier)
        mapView.layoutMargins = UIEdgeInsets(top: view.safeAreaInsets.top + 94 + 20, left: 20, bottom: view.safeAreaInsets.bottom + cardPeekCollectionView.frame.height + 30 + 8, right: 20)
    }
    
    private func setupTopicsTrendingCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = UICollectionViewFlowLayout.automaticSize
        layout.estimatedItemSize = CGSize(width: 120, height: 40)
        layout.minimumLineSpacing = 12
        layout.sectionInset.left = 18
        layout.sectionInset.right = 48
        layout.minimumInteritemSpacing = 0
        topicsTrendingCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        topicsTrendingCollectionView.translatesAutoresizingMaskIntoConstraints = false
        topicsTrendingCollectionView.backgroundColor = .clear
        topicsTrendingCollectionView.showsHorizontalScrollIndicator = false
        topicsTrendingCollectionView.showsVerticalScrollIndicator = false
        topicsTrendingCollectionView.clipsToBounds = false
        topicsTrendingCollectionView.allowsSelection = true
        topicsTrendingCollectionView.allowsMultipleSelection = true
        topicsTrendingCollectionView.alwaysBounceHorizontal = true
        topicsTrendingCollectionView.register(TopicTrendingCollectionViewCell.self, forCellWithReuseIdentifier: "topicTrending")
        topicsTrendingCollectionView.dataSource = self
        topicsTrendingCollectionView.delegate = self
        view.addSubview(topicsTrendingCollectionView)
        
        NSLayoutConstraint.activate([
            topicsTrendingCollectionView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 8),
            topicsTrendingCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            topicsTrendingCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            topicsTrendingCollectionView.heightAnchor.constraint(equalToConstant: 40),
        ])
    }
    
    private func setupToggleCollectionView() {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 60, height: 60)
        layout.minimumLineSpacing = 12
        layout.minimumInteritemSpacing = 0
        togglesCollectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        togglesCollectionView.translatesAutoresizingMaskIntoConstraints = false
        togglesCollectionView.backgroundColor = .clear
        togglesCollectionView.showsHorizontalScrollIndicator = false
        togglesCollectionView.showsVerticalScrollIndicator = false
        togglesCollectionView.alwaysBounceHorizontal = true
        togglesCollectionView.clipsToBounds = false
        togglesCollectionView.allowsSelection = true
        togglesCollectionView.allowsMultipleSelection = true
        togglesCollectionView.contentInset.left = 18
        togglesCollectionView.contentInset.right = 18
        togglesCollectionView.register(CircularToggleCollectionViewCell.self, forCellWithReuseIdentifier: "circularToggle")
        togglesCollectionView.dataSource = self
        togglesCollectionView.delegate = self
        view.addSubview(togglesCollectionView)
        
        NSLayoutConstraint.activate([
            togglesCollectionView.topAnchor.constraint(equalTo: topicsTrendingCollectionView.bottomAnchor, constant: 20),
            togglesCollectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            togglesCollectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            togglesCollectionView.heightAnchor.constraint(equalToConstant: 60),
        ])
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        if !initialFetchMade {
            LocationManager.shared.startUpdatingLocation()
        }
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        
        LocationManager.shared.stopUpdatingLocation()
    }
    
    private func setupCollectionView() {
        collectionViewFlowLayout.minimumLineSpacing = 0
        collectionViewFlowLayout.scrollDirection = .horizontal
        cardPeekCollectionView.register(MCExploreCardCollectionViewCell.self, forCellWithReuseIdentifier: "exploreCard")
        cardPeekCollectionView.register(ExploreEmptyStateCardCollectionViewCell.self, forCellWithReuseIdentifier: "emptyStateCard")
        cardPeekCollectionView.dataSource = self
        cardPeekCollectionView.delegate = self
        cardPeekCollectionView.backgroundColor = .clear
        cardPeekCollectionView.clipsToBounds = false
        cardPeekCollectionView.showsHorizontalScrollIndicator = false
        cardPeekCollectionView.collectionViewLayout = collectionViewFlowLayout
        cardPeekCollectionView.alwaysBounceHorizontal = true
        collectionViewHeightConstraint = cardPeekCollectionView.heightAnchor.constraint(greaterThanOrEqualToConstant: self.view.frame.height * 3 / 7 - 70)
        collectionViewHeightConstraint.priority = .defaultHigh
        NSLayoutConstraint.activate([
            collectionViewHeightConstraint
        ])
    }
    
    func fetchNearbyPackages() {
        print("fetch nearby")
        LocationManager.shared.requestLocation()
        if let location = LocationManager.shared.location {
            
            initialFetchMade = true
            let index: Index!
            
            let query = Query(query: "")
            query.attributesToRetrieve = ["_geoloc", "content", "logistics", "relations", "objectID"]

            index = apiClient.index(withName: "packages")
            // sort by distance by default
            query.aroundLatLng = LatLng(lat: location.coordinate.latitude, lng: location.coordinate.longitude)
//            query.aroundRadius = .explicit(300000)
            
            var filterString = "NOT logistics.status:\(getStringForStatusEnum(statusEnum: .delivered))"
            
            if let category = self.category {
                filterString += " AND content.category:\(getStringForCategory(category: category))"
            }
            
            if let topicName = self.topicName {
                filterString += " AND content.topic.name:\(topicName)"
            }
            
//            if let status = self.status {
//                if self.topicName != nil && !self.topicName!.isEmpty {
//                    filterString += " AND logistics.status:\(getStringForStatusEnum(statusEnum: status))"
//                } else {
//                    filterString += "NOT logistics.status:\(getStringForStatusEnum(statusEnum: .delivered))"
//                }
//                query.filters = filterString
//            }
            
            
            print(filterString)
            
            query.filters = filterString
            
            index.search(query, completionHandler: { (content, error) -> Void in
                if error == nil {
                    var packages: [Package] = []
                    self.mapView.removeAnnotations(self.annotations)
                    self.annotations.removeAll()
                    self.packages.removeAll()
                    guard let hits = content!["hits"] as? [[String: AnyObject]] else {
                        print("hits error")
                        return
                    }
                    for hit in hits {
                        let package = Package(hit: hit)
                        packages.append(package)
                        
                        let packageAnnotation = PackageAnnotation(with: package)
                        self.annotations.append(packageAnnotation)
                    }
                    self.packages.removeAll()
                    self.packages = packages
                    self.cardPeekCollectionView.reloadData()
                    let height: CGFloat = self.cardPeekCollectionView.collectionViewLayout.collectionViewContentSize.height
                    self.collectionViewHeightConstraint.constant = height
                    self.view.layoutIfNeeded()

                    DispatchQueue.main.async {
                        if self.annotations.count > 0 {
                            // construct new annotations

                        let newAnnotations = self.annotationsByDistributingAnnotations(annotations: self.annotations) { (oldAnnotation:PackageAnnotation, newCoordinate:CLLocationCoordinate2D) in
                            return PackageAnnotation(with: oldAnnotation.title, coordinate: newCoordinate, package: oldAnnotation.package!)
                        }
                        
                        var newPackages:[Package] = []
                        for annotation in newAnnotations {
                            newPackages.append(annotation.package!)
                        }
                        self.packages = newPackages
                        self.cardPeekCollectionView.reloadData()
                        
                        self.mapView.removeAnnotations(self.mapView.annotations)
                        self.annotations = newAnnotations
                        self.mapView.showAnnotations(self.annotations, animated: true)
                        self.mapView.selectAnnotation(self.annotations.first!, animated: true)
                        
                        }
                        if self.cardPeekCollectionView.numberOfItems(inSection: 0) == 0 {
                            self.cardPeekCollectionView.isUserInteractionEnabled = false
                        } else {
                            self.cardPeekCollectionView.isUserInteractionEnabled = true
                        }
                    }
                } else {
                    print(error?.localizedDescription)
                }
            })
        } else {
            print("location not ready")
        }
        
    }
    
    private func fetchTopics() {
        let index: Index = apiClient.index(withName: "topics")
        
        let query = Query(query: "")
        query.attributesToRetrieve = ["name", "objectID"]

        index.search(query, completionHandler: { (content, error) -> Void in
            if error == nil {
                guard let hits = content!["hits"] as? [[String: AnyObject]] else {
                    print("hits error")
                    return
                }
                for hit in hits {
                    let topic = TopicResultItem(with: hit)
                    self.topics.append(topic)
                }
                DispatchQueue.main.async {
                    self.topicsTrendingCollectionView.reloadData()
                }
            } else {
                print(error?.localizedDescription)
            }
        })
    }
    
    private static let radiusOfEarth = Double(6378100)
    
    typealias annotationRelocator = ((_ oldAnnotation:PackageAnnotation, _ newCoordinate:CLLocationCoordinate2D) -> (PackageAnnotation))
    
    private func annotationsByDistributingAnnotations(annotations: [PackageAnnotation], constructNewAnnotationWithClosure ctor: annotationRelocator) -> [PackageAnnotation] {
        
        // 1. group the annotations by coordinate
        
        self.coordinateToAnnotations = ExploreViewController.groupAnnotationsByCoordinate(annotations: annotations)
        
        // 2. go through the groups and redistribute
        
        var newAnnotations = [PackageAnnotation]()

        for (coordinate, annotationsAtCoordinate) in coordinateToAnnotations! {

            
            
            // end create modifiedAnnotations
            
            let newAnnotationsAtCoordinate = self.annotationsByDistributingAnnotationsContestingACoordinate(annotations: annotationsAtCoordinate, constructNewAnnotationWithClosure: ctor)

            newAnnotations.append(contentsOf: newAnnotationsAtCoordinate)
            self.coordinateToNewAnnotations.updateValue(newAnnotationsAtCoordinate, forKey: coordinate)
        }
        return newAnnotations
    }
    
    private static func groupAnnotationsByCoordinate(annotations: [PackageAnnotation]) -> [CLLocationCoordinate2D: [PackageAnnotation]] {
        var coordinateToAnnotations = [CLLocationCoordinate2D: [PackageAnnotation]]()
        for annotation in annotations {
            let coordinate = annotation.coordinate
            let annotationsAtCoordinate = coordinateToAnnotations[coordinate] ?? [PackageAnnotation]()
            coordinateToAnnotations[coordinate] = annotationsAtCoordinate + [annotation]
        }
        return coordinateToAnnotations
    }
    
    private func annotationsByDistributingAnnotationsContestingACoordinate(annotations: [PackageAnnotation], constructNewAnnotationWithClosure ctor: annotationRelocator) -> [PackageAnnotation] {
        
        var newAnnotations = [PackageAnnotation]()
        
        let contestedCoordinates = annotations.map{ $0.coordinate }
        
        let newCoordinates = ExploreViewController.coordinatesByDistributingCoordinates(coordinates: contestedCoordinates)
        
        for (i, annotation) in annotations.enumerated() {
            
            let newCoordinate = newCoordinates[i]
            
            let newAnnotation = ctor(annotation, newCoordinate)
            
            if annotations.count > 1 {
                self.modifiedAnnotations.append(newAnnotation)
            }

            newAnnotations.append(newAnnotation)
        }
        
        // create modifiedAnnotations
        
        
        return newAnnotations
    }
    
    private static func coordinatesByDistributingCoordinates(coordinates: [CLLocationCoordinate2D]) -> [CLLocationCoordinate2D] {
        
        if coordinates.count == 1 {
            return coordinates
        }
        
        var result = [CLLocationCoordinate2D]()
        
        let distanceFromContestedLocation: Double = 3.0 * Double(coordinates.count) / 2.0
        let radiansBetweenAnnotations = (.pi * 2) / Double(coordinates.count)
        
        for (i, coordinate) in coordinates.enumerated() {
            
            let bearing = radiansBetweenAnnotations * Double(i)
            let newCoordinate = calculateCoordinateFromCoordinate(coordinate: coordinate, onBearingInRadians: bearing, atDistanceInMetres: distanceFromContestedLocation)
            
            result.append(newCoordinate)
        }
        
        return result
    }
    
    private static func calculateCoordinateFromCoordinate(coordinate: CLLocationCoordinate2D, onBearingInRadians bearing: Double, atDistanceInMetres distance: Double) -> CLLocationCoordinate2D {
        
        let coordinateLatitudeInRadians = coordinate.latitude * .pi / 180;
        let coordinateLongitudeInRadians = coordinate.longitude * .pi / 180;
        
        let distanceComparedToEarth = distance / radiusOfEarth;
        
        let resultLatitudeInRadians = asin(sin(coordinateLatitudeInRadians) * cos(distanceComparedToEarth) + cos(coordinateLatitudeInRadians) * sin(distanceComparedToEarth) * cos(bearing));
        let resultLongitudeInRadians = coordinateLongitudeInRadians + atan2(sin(bearing) * sin(distanceComparedToEarth) * cos(coordinateLatitudeInRadians), cos(distanceComparedToEarth) - sin(coordinateLatitudeInRadians) * sin(resultLatitudeInRadians));
        
        let latitude = resultLatitudeInRadians * 180 / .pi;
        let longitude = resultLongitudeInRadians * 180 / .pi;
        
        return CLLocationCoordinate2D(latitude: latitude, longitude: longitude)
    }
}


extension ExploreViewController: MKMapViewDelegate {
    func mapView(_ mapView: MKMapView, viewFor annotation: MKAnnotation) -> MKAnnotationView? {
        if let userLocation = annotation as? MKUserLocation {
            userLocation.title = ""
            return nil
        } else if annotation is PackageAnnotation {
            let category = (annotation as! PackageAnnotation).package!.category
            let stamp = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultAnnotationViewReuseIdentifier, for: annotation) as! MKMarkerAnnotationView
            
            stamp.glyphText = getEmojiForCategory(category: category)
            stamp.markerTintColor = getTintForCategory(category: category)
            stamp.animatesWhenAdded = true
            stamp.displayPriority = .required
            if self.modifiedAnnotations.contains(annotation as! PackageAnnotation) {
                stamp.clusteringIdentifier = String(describing: PackagesClusterView.self)
            } else {
                stamp.clusteringIdentifier = nil
            }
            stamp.titleVisibility = .hidden
            return stamp
        } else if annotation is MKClusterAnnotation {
            let clusterStamp = mapView.dequeueReusableAnnotationView(withIdentifier: MKMapViewDefaultClusterAnnotationViewReuseIdentifier, for: annotation) as! PackagesClusterView
            return clusterStamp
        } else {
            return nil
        }
    }
    
    func mapView(_ mapView: MKMapView, didSelect view: MKAnnotationView) {
        if view.annotation!.isMember(of: MKUserLocation.self) {
            print("tapped user location")
        } else if view.annotation!.isMember(of: PackageAnnotation.self) {
//            (view as! MKMarkerAnnotationView).markerTintColor = Theme().mapStampTint
            let package = (view.annotation as! PackageAnnotation).package
            if let indexOfPackage = self.packages.index(where: { $0.reference == package!.reference}) {
                if indexOfPackage != indexOfMajorCell(){
                    cardPeekCollectionView.scrollToItem(at: IndexPath(item: indexOfPackage, section: 0), at: .centeredHorizontally, animated: true)
                }
            }
        } else if let cluster = view.annotation as? MKClusterAnnotation {
            let coordinates = cluster.memberAnnotations.map { $0.coordinate }
            let region = MKCoordinateRegion(coordinates: coordinates)!
            
            mapView.setRegion(region, animated: true)
            let package = (cluster.memberAnnotations.first as! PackageAnnotation).package
            if let indexOfPackage = self.packages.index(where: { $0.reference == package!.reference}) {
                if indexOfPackage != indexOfMajorCell(){
                    cardPeekCollectionView.scrollToItem(at: IndexPath(item: indexOfPackage, section: 0), at: .centeredHorizontally, animated: true)
                    print("select map")
                    mapView.selectAnnotation(cluster.memberAnnotations.first!, animated: true)
                }
            }

        } else {
            print("tapped")
        }
    }
    
    func mapView(_ mapView: MKMapView, didDeselect view: MKAnnotationView) {
        if view.annotation!.isMember(of: PackageAnnotation.self) {
            (view as! MKMarkerAnnotationView).markerTintColor = getTintForCategory(category: (view.annotation as! PackageAnnotation).package!.category)
        }
    }
    
    func mapView(_ mapView: MKMapView, didUpdate userLocation: MKUserLocation) {
        let userLocationView = mapView.view(for: userLocation)
        userLocationView?.canShowCallout = false
        userLocationView?.isEnabled = false
    }
    
}

extension ExploreViewController: UICollectionViewDelegate {
    func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
        if scrollView == self.cardPeekCollectionView {
            indexOfCellBeforeDragging = indexOfMajorCell()
        }
    }
    
    func scrollViewWillEndDragging(_ scrollView: UIScrollView, withVelocity velocity: CGPoint, targetContentOffset: UnsafeMutablePointer<CGPoint>) {
        if scrollView == self.cardPeekCollectionView && self.packages.count > 0 {
            // Stop scrollView sliding:
            targetContentOffset.pointee = scrollView.contentOffset
            
            // calculate where scrollView should snap to:
            let indexOfMajorCell = self.indexOfMajorCell()
            
            // calculate conditions:
            let dataSourceCount = cardPeekCollectionView.numberOfItems(inSection: 0)
            let swipeVelocityThreshold: CGFloat = 0.5 // after some trail and error
            let hasEnoughVelocityToSlideToTheNextCell = indexOfCellBeforeDragging + 1 < dataSourceCount && velocity.x > swipeVelocityThreshold
            let hasEnoughVelocityToSlideToThePreviousCell = indexOfCellBeforeDragging - 1 >= 0 && velocity.x < -swipeVelocityThreshold
            let majorCellIsTheCellBeforeDragging = indexOfMajorCell == indexOfCellBeforeDragging
            let didUseSwipeToSkipCell = majorCellIsTheCellBeforeDragging && (hasEnoughVelocityToSlideToTheNextCell || hasEnoughVelocityToSlideToThePreviousCell)
            
            if didUseSwipeToSkipCell {
                print("did use swipe to skip cell")
                let snapToIndex = indexOfCellBeforeDragging + (hasEnoughVelocityToSlideToTheNextCell ? 1 : -1)
                let toValue = collectionViewFlowLayout.estimatedItemSize.width * CGFloat(snapToIndex)
                
                // Damping equal 1 => no oscillations => decay animation:
                UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 1, initialSpringVelocity: velocity.x, options: .allowUserInteraction, animations: {
                    scrollView.contentOffset = CGPoint(x: toValue, y: 0)
                    scrollView.layoutIfNeeded()
                }, completion: nil)
            } else {
                print("did drag to index \(indexOfMajorCell)")
                var targetIndex: Int?
                if indexOfMajorCell < 0 {
                    targetIndex = 0
                } else if indexOfMajorCell > self.packages.count - 1 {
                    targetIndex = self.packages.count - 1
                } else {
                    targetIndex = indexOfMajorCell
                }
                // This is a much better to way to scroll to a cell:
                let indexPath = IndexPath(row: targetIndex!, section: 0)
                collectionViewFlowLayout.collectionView!.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
                mapView.selectAnnotation(self.annotations[targetIndex!], animated: true)
                mapView.setCenter(self.annotations[targetIndex!].coordinate, animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if collectionView == cardPeekCollectionView && self.packages.count > 0 {
            (cell as! MCExploreCardCollectionViewCell).progressBarView.animateProgress()
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        if scrollView == cardPeekCollectionView && self.packages.count > 0 {
            print("select map")
            let indexOfMajorCell = self.indexOfMajorCell()
            var targetIndex: Int?
            if indexOfMajorCell < 0 {
                targetIndex = 0
            } else if indexOfMajorCell > self.packages.count - 1 {
                targetIndex = self.packages.count - 1
            } else {
                targetIndex = indexOfMajorCell
            }

            mapView.selectAnnotation(self.annotations[targetIndex!], animated: true)
            mapView.setCenter(self.annotations[targetIndex!].coordinate, animated: true)
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        print("did select \(indexPath)")
        if collectionView == cardPeekCollectionView {
            if self.packages.count > 0 {
                let packageOfSelected = packages[indexPath.item]
                delegate?.showPackageDetail(with: packageOfSelected)
            } else {
                self.clearFilters()
            }
        }
        if collectionView == togglesCollectionView {
            if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
                for selectedIndexPath in selectedIndexPaths {
                    collectionView.deselectItem(at: selectedIndexPath, animated: false)
                    if let cell = collectionView.cellForItem(at: selectedIndexPath) as? CircularToggleCollectionViewCell {
                        cell.containerView.backgroundColor = .white
                    }

                }
            }
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionView.ScrollPosition(rawValue:0))
            let category = packageCategoriesEnumArray[indexPath.item]
            self.category = category
            if let cell = collectionView.cellForItem(at: indexPath) as? CircularToggleCollectionViewCell {
                cell.containerView.backgroundColor = getTintForCategory(category: category)
            }
        }
        if collectionView == topicsTrendingCollectionView {
            if let selectedIndexPaths = collectionView.indexPathsForSelectedItems {
                for selectedIndexPath in selectedIndexPaths {
                    collectionView.deselectItem(at: selectedIndexPath, animated: false)
                    if let cell = collectionView.cellForItem(at: selectedIndexPath) as? TopicTrendingCollectionViewCell {
                        cell.containerView.backgroundColor = .white
                        cell.label.textColor = Theme().grayTextColor
                    }
                    
                }
            }
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: UICollectionView.ScrollPosition(rawValue:0))
            self.topicName = topics[indexPath.item].name
            if let cell = collectionView.cellForItem(at: indexPath) as? TopicTrendingCollectionViewCell {
                cell.containerView.backgroundColor = Theme().textColor
                cell.label.textColor = .white
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        print("did deselect \(indexPath)")
        if collectionView == togglesCollectionView {
            self.category = nil
            if let cell = collectionView.cellForItem(at: indexPath) as? CircularToggleCollectionViewCell {
                cell.containerView.backgroundColor = .white
            }
            self.togglesCollectionView.deselectItem(at: indexPath, animated: false)
        }
        if collectionView == topicsTrendingCollectionView {
            self.topicName = nil
            self.selectedTopicIndex = nil
            if let cell = collectionView.cellForItem(at: indexPath) as? TopicTrendingCollectionViewCell {
                cell.containerView.backgroundColor = .white
                cell.label.textColor = Theme().grayTextColor
            }
            self.topicsTrendingCollectionView.deselectItem(at: indexPath, animated: false)
        }
    }
    
}

extension ExploreViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == cardPeekCollectionView {
            return packages.count > 0 ? packages.count : 1
        } else if collectionView == togglesCollectionView {
            // toggles
            return packageCategoriesEnumArray.count
        } else {
            return topics.count
        }
    }
    
    @objc private func didTapClearFilters(sender: UIButton) {
        clearFilters()
    }
    
    private func clearFilters() {
        self.category = nil
        self.topicName = nil
        self.topicsTrendingCollectionView.reloadData()
        self.togglesCollectionView.reloadData()
        self.fetchNearbyPackages()
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == cardPeekCollectionView {
            if packages.count > 0 {
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "exploreCard", for: indexPath) as! MCExploreCardCollectionViewCell
                cell.package = packages[indexPath.item]
                cell.cellWidth = collectionViewFlowLayout.estimatedItemSize.width
                cell.layout()
                return cell
            } else {
                // empty state card
                let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "emptyStateCard", for: indexPath) as! ExploreEmptyStateCardCollectionViewCell
                if self.category != nil || self.topicName != nil {
                    // some filter applied, show action button
                    cell.emptyStateView.actionButton.isHidden = false
                    cell.emptyStateView.actionButton.setTitle(String(NSLocalizedString("button.clearFilters", comment: "button title for clear filters")), for: .normal)
                    cell.emptyStateView.actionButton.addTarget(self, action: #selector(didTapClearFilters(sender:)), for: .touchUpInside)
                    cell.emptyStateView.subtitleLabel.text = String(NSLocalizedString("label.noPackagesFound", comment: "label text for no packages found"))
                } else {
                    // no filter applied, hide button and update subtitle label text
                    cell.emptyStateView.actionButton.isHidden = true
                    cell.emptyStateView.subtitleLabel.text = String(NSLocalizedString("label.noPackagesNearby", comment: "label text for no packages nearby"))
                }
                cell.cellWidth = collectionViewFlowLayout.estimatedItemSize.width
                cell.cellHeight = collectionViewFlowLayout.estimatedItemSize.height
                cell.layout()
                return cell
            }
        } else if collectionView == togglesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "circularToggle", for: indexPath) as! CircularToggleCollectionViewCell
            let category = packageCategoriesEnumArray[indexPath.item]
            cell.label.text = getEmojiForCategory(category: category)
            if category == self.category {
                cell.containerView.backgroundColor = getTintForCategory(category: category)
            } else {
                cell.containerView.backgroundColor = .white
            }
            return cell
        } else {
            let topic = self.topics[indexPath.item]
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "topicTrending", for: indexPath) as! TopicTrendingCollectionViewCell
            cell.label.text = "#\(topic.name)"
            if self.topicName != nil && self.topicName == topic.name {
                cell.containerView.backgroundColor = Theme().textColor
                cell.label.textColor = .white
            } else {
                cell.containerView.backgroundColor = .white
                cell.label.textColor = Theme().grayTextColor
            }
            return cell
        }
    }
    
}

extension ExploreViewController: CLLocationManagerDelegate {
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        if !initialFetchMade {
            fetchNearbyPackages()
        }
    }
    
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        print("location manager fail with error: \(error)")
    }
}

//  MARK: Battle Rapper Cluster View
internal final class PackagesClusterView: MKMarkerAnnotationView {
    //  MARK: Properties
    internal override var annotation: MKAnnotation? { willSet { newValue.flatMap(configure(with:)) } }
    //  MARK: Initialization
    override init(annotation: MKAnnotation?, reuseIdentifier: String?) {
        super.init(annotation: annotation, reuseIdentifier: reuseIdentifier)
        displayPriority = .defaultHigh
        collisionMode = .circle
    }
    required init?(coder aDecoder: NSCoder) {
        fatalError("\(#function) not implemented.")
    }
}
//  MARK: Configuration
private extension PackagesClusterView {
    func configure(with annotation: MKAnnotation) {
        guard let annotation = annotation as? MKClusterAnnotation else { return }
        let count = annotation.memberAnnotations.count
        titleVisibility = .hidden
        subtitleVisibility = .hidden
        markerTintColor = Theme().textColor
        glyphTintColor = .white
        glyphText = "\(count)"
    }
}

extension CLLocationCoordinate2D: Hashable {
    public var hashValue: Int {
        get {
            return (latitude.hashValue&*397) &+ longitude.hashValue;
        }
    }
}

public func ==(lhs: CLLocationCoordinate2D, rhs: CLLocationCoordinate2D) -> Bool {
    return lhs.latitude == rhs.latitude && lhs.longitude == rhs.longitude
}

extension Dictionary where Value: Equatable {
    func someKey(forValue val: Value) -> Key? {
        return first(where: { $1 == val })?.key
    }
}

extension MKCoordinateRegion {
    
    init?(coordinates: [CLLocationCoordinate2D]) {
        
        // first create a region centered around the prime meridian
        let primeRegion = MKCoordinateRegion.region(for: coordinates, transform: { $0 }, inverseTransform: { $0 })
        
        // next create a region centered around the 180th meridian
        let transformedRegion = MKCoordinateRegion.region(for: coordinates, transform: MKCoordinateRegion.transform, inverseTransform: MKCoordinateRegion.inverseTransform)
        
        // return the region that has the smallest longitude delta
        if let a = primeRegion,
            let b = transformedRegion,
            let min = [a, b].min(by: { $0.span.longitudeDelta < $1.span.longitudeDelta }) {
            self = min
        }
            
        else if let a = primeRegion {
            self = a
        }
            
        else if let b = transformedRegion {
            self = b
        }
            
        else {
            return nil
        }
    }
    
    // Latitude -180...180 -> 0...360
    private static func transform(c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        if c.longitude < 0 { return CLLocationCoordinate2DMake(c.latitude, 360 + c.longitude) }
        return c
    }
    
    // Latitude 0...360 -> -180...180
    private static func inverseTransform(c: CLLocationCoordinate2D) -> CLLocationCoordinate2D {
        if c.longitude > 180 { return CLLocationCoordinate2DMake(c.latitude, -360 + c.longitude) }
        return c
    }
    
    private typealias Transform = (CLLocationCoordinate2D) -> (CLLocationCoordinate2D)
    
    private static func region(for coordinates: [CLLocationCoordinate2D], transform: Transform, inverseTransform: Transform) -> MKCoordinateRegion? {
        
        // handle empty array
        guard !coordinates.isEmpty else { return nil }
        
        // handle single coordinate
        guard coordinates.count > 1 else {
            return MKCoordinateRegion(center: coordinates[0], span: MKCoordinateSpan(latitudeDelta: 1, longitudeDelta: 1))
        }
        
        let transformed = coordinates.map(transform)
        
        // find the span
        let minLat = transformed.min { $0.latitude < $1.latitude }!.latitude
        let maxLat = transformed.max { $0.latitude < $1.latitude }!.latitude
        let minLon = transformed.min { $0.longitude < $1.longitude }!.longitude
        let maxLon = transformed.max { $0.longitude < $1.longitude }!.longitude
        let span = MKCoordinateSpan(latitudeDelta: maxLat - minLat, longitudeDelta: maxLon - minLon)
        
        // find the center of the span
        let center = inverseTransform(CLLocationCoordinate2DMake((maxLat - span.latitudeDelta / 2), maxLon - span.longitudeDelta / 2))
        
        return MKCoordinateRegion(center: center, span: span)
    }
}
