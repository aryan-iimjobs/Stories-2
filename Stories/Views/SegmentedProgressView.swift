//
//  SegmentedProgressView.swift
//  Stories
//
//  Created by Aryan Sharma on 26/05/20.
//  Copyright © 2020 Iimjobs. All rights reserved.
//

import UIKit

///Protocol needs to be implemented by the parent view of **SegmentedProgressView**.
///Defines  methods which notify about progress of  segmented bars.
protocol SegmentedProgressViewDelegate: class {
    ///Invoked when a segmented bar gets full.
    ///- parameter index: Position of the next bar after its previous bar is filled.
    func segmentedProgressBarChangedIndex(index: Int)
    
    ///Invoked when all the bars are filled of the **SegmentedProgressView**.
    ///- parameter left: Indicates if next **SegmentedProgressView** is to the left (Previous story)
    ///or right (Next Story) side of the screen.
    func segmentedProgressBarsFinished(left: Bool)
}

///Custom UIView which is basically an horizontal array of **UIProgressView**'s and
///provides control over each progress bar.
class SegmentedProgressView: UIView {

    weak var delegate: SegmentedProgressViewDelegate?

    //MARK: constants
    ///Space between two bars or UIProgressView's.
    let PADDING: CGFloat = 4.0
    
    //MARK: properties
    ///Duration for the current bar to completely fill.
    var currentDuration: Double = 5
    ///Index of current bar which is being filled.
    var currentAnimationIndex = 0
    
    //MARK: flags
    ///If filling process of bars is currently paused.
    var isPaused = false

    //MARK: object references
    ///Timer which loops the filling of the bars.
    var timer: Timer?
    ///Background shadow layer.
    let gradientLayer = CAGradientLayer()
    
    //MARK: data holders
    ///Array that holds references to all the bars of the **SegmentedProgressView**.
    var arrayBars: [UIProgressView] = []
    
    ///Creates an instance of **SegmentedProgressView**.
    
    ///Creates the bars and setups other views or layers.
    ///- parameter barCount: Number of  horizontal bars to create.
    ///- returns: Instance of **SegmentedProgressView**.
    init(barCount: Int) {
        super.init(frame: .zero)
        var count = barCount
        if barCount <= 0 {
            count = 1
        }
        for _ in 0..<count {
            let bar = UIProgressView()
            arrayBars.append(bar)
            addSubview(bar)
        }
        setupViews()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func setupViews() {
        gradientLayer.colors = [UIColor(red: 38/255, green: 38/255, blue: 38/255, alpha: 0.3).cgColor,UIColor(red: 0, green: 0, blue: 0, alpha: 0).cgColor]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
        layer.insertSublayer(gradientLayer, at: 0)
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        gradientLayer.frame = bounds
        ///Calculate width of each bar such that they cover the screen.
        let width = (frame.width - ((PADDING) * CGFloat(arrayBars.count - 1)) - 16) / CGFloat(arrayBars.count)
        
        for (index, progressBar) in arrayBars.enumerated() {
            
            let segFrame = CGRect(x: (CGFloat(index) * (width + PADDING)) + 8, y: frame.height/2 - 1, width: width, height: 20)
            progressBar.frame = segFrame
            
            progressBar.tintColor = .white
            progressBar.backgroundColor = UIColor.lightGray
            progressBar.layer.cornerRadius = progressBar.frame.height / 2
        }
    }
    
    ///Starts the timer to start filling a bar.
    ///- parameter index: Index of the bar to be filled.
    ///- parameter duration: How long the bar should be filled in seconds.
    func animate(index: Int, duration: Double) {
        currentDuration = duration
        let duration = duration / 200.0
        isPaused = false
        timer = Timer.scheduledTimer(timeInterval: TimeInterval(duration), target: self, selector: #selector(updateProgressBar(_:)), userInfo: nil, repeats: true)
        currentAnimationIndex = index
    }
    
    ///Method called by the timer to fill current bar periodically.
    @objc func updateProgressBar(_ timer: Timer) {
        if currentAnimationIndex >= arrayBars.count || currentAnimationIndex < 0 { return }
        
        let progressBar = arrayBars[currentAnimationIndex]
        progressBar.progress += 0.005
        progressBar.setProgress(progressBar.progress, animated: false)
        if  progressBar.progress == 1.0 {
            next()
        }
    }
    
    ///Method called when current bar is filled and need to move to next bar, if present else move to next company's story.
    func next() {
        print("PV: invalidate timer")
        
        let newIndex = currentAnimationIndex + 1
        
        print("new index...\(newIndex)...array bar count\(arrayBars.count)")
        
        if newIndex < arrayBars.count {
            print("PV: next snap")
            timer?.invalidate()
            currentAnimationIndex = newIndex
            delegate?.segmentedProgressBarChangedIndex(index: newIndex)
        } else {
            print("PV: Story ended")
            timer?.invalidate()
            delegate?.segmentedProgressBarsFinished(left: false)
        }
    }
    
    ///Invalidate the timer to mimic pause.
    func pause() {
        if !isPaused{
            isPaused = true
            print("PV: pause")
            timer?.invalidate()
        }
    }
    
    ///Start the timer from paused state.
    func resume() {
        if isPaused {
            isPaused = false
            print("PV: resume")
            self.animate(index: currentAnimationIndex, duration: currentDuration)
        }
    }
    
    ///Set progress of all the bars to zero and invalidate the timer.
    func resetBars() {
        for i in arrayBars {
            i.progress = 0.0
        }
        timer?.invalidate()
        currentAnimationIndex = 0
        isPaused = false
        print("PV: reset Bars")
    }
    
    ///Force fill current bar and  move to next bar.
    func skip() {
        if isPaused {
            isPaused = false
        }
        print("PV: skip")
        if currentAnimationIndex >= arrayBars.count || currentAnimationIndex < 0 { return }
        
        let currentBar = arrayBars[currentAnimationIndex]
        currentBar.progress = 1.0
        next()
    }
    
    ///Set progress of current bar to zero and move to previous bar, if present else move to previous company's story.
    func rewind() {
        print("PV: rewind")
        if isPaused { isPaused = false }
        
        if currentAnimationIndex >= arrayBars.count || currentAnimationIndex < 0 { return }
        
        let currentBar = arrayBars[currentAnimationIndex]
        currentBar.progress = 0.0
        
        let newIndex = currentAnimationIndex - 1
        
        if newIndex < 0 {
            print("PV: Story ended , go to previous story")
            timer?.invalidate()
            delegate?.segmentedProgressBarsFinished(left: true)
            return
        }
        
        timer?.invalidate()
        if newIndex >= arrayBars.count || newIndex < 0 { return }
        let prevBar = arrayBars[newIndex]
        prevBar.setProgress(0.0, animated: false)
        
        currentAnimationIndex = newIndex
        delegate?.segmentedProgressBarChangedIndex(index: newIndex)
    }
    
    ///Start filling a specific bar and fill all the bars before it.
    ///- parameter index: Position of the bar to be filled.
    func startfrom(index: Int) {
        if index >= arrayBars.count || index < 0 { return }
        currentAnimationIndex = index
        for i in 0..<index {
            DispatchQueue.main.async {
                self.arrayBars[i].setProgress(1.0, animated: false)
            }
        }
    }
}
