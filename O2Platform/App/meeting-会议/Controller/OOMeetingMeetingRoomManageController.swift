//
//  OOMeetingMeetingRoomManageController.swift
//  o2app
//
//  Created by 刘振兴 on 2018/1/4.
//  Copyright © 2018年 zone. All rights reserved.
//

import UIKit
import EmptyDataSet_Swift

private let reuseIdentifier = "OOMeetingRoomMainCell"

class OOMeetingMeetingRoomManageController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    private lazy var cellBackView:UIView = {
        let view = Bundle.main.loadNibNamed("OOMeetingBackgroundView", owner: self, options: nil)?.first as! UIView
        return view
    }()
    
    //开始时间
    var startDate:Date = Date()
    
    //结束时间
    var endDate:Date = Date()
    
    //当前模式 0--正常 1--被选择 2--被选择多选
    var currentMode:Int = 0 {
        didSet {
           
        }
    }
    
    var delegate:OOCommonBackResultDelegate?
    
    private var selectedMeetingRooms:[OOMeetingRoomInfo] = []
    
    private var selectedCellIndexPaths:[IndexPath] = []
    
    
    private lazy var headerView:OOMeetingRoomTableHeaderView = {
       let view = Bundle.main.loadNibNamed("OOMeetingRoomTableHeaderView", owner: self, options: nil)?.first as! OOMeetingRoomTableHeaderView
        view.setDelegate = self
        return view
    }()
    
    private lazy var viewModel:OOMeetingRoomViewModel = {
        return OOMeetingRoomViewModel()
    }()
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        title = "会议室"
        self.tabBarItem?.selectedImage = O2ThemeManager.image(for: "Icon.icon_huiyishi_pro")
        self.view.backgroundColor = UIColor(hex: "#f5f5f5")
        headerView.sizeToFit()
        headerView.autoresizingMask = .flexibleWidth
        //设置选择时间
        headerView.setChooseDate(startTime: self.startDate, endTime: self.endDate)
        
        tableView.tableHeaderView = headerView
        //tableView.tableHeaderView?.frame = CGRect(x: 0, y: 0, width: SCREEN_WIDTH, height: 44)
        tableView.tableFooterView = UIView()
        tableView.register(UINib.init(nibName: "OOMeetingRoomMainCell", bundle: nil), forCellReuseIdentifier: reuseIdentifier)
        //tableView.emptyDataSetSource = self
        tableView.dataSource = self
        //tableView.emptyDataSetDelegate = self
        tableView.delegate = self
        if currentMode != 0 {
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(title:"确认", style: .plain, target: self, action: #selector(selectSubmit(_:)))
        }
        if currentMode == 1 {
            self.tableView.allowsSelection = true
        }else if currentMode == 2 {
            self.tableView.allowsMultipleSelection = true
        }
        tableView.mj_header = MJRefreshNormalHeader(refreshingBlock: {
             self.loadAllBuildByDate(self.headerView.startDate, self.headerView.completedDate)
        })
        
        loadAllBuildByDate(headerView.startDate, headerView.completedDate)
    }
    
    private func loadAllBuildByDate(_ startDate:String,_ endDate:String){
        self.showLoading()
        viewModel.loadAllBuildByDate(startDate, endDate).then { (builds) in
            DispatchQueue.main.async {
                self.viewModel.builds.removeAll()
                self.viewModel.builds.append(contentsOf: builds)
                self.tableView.reloadData()
            }
            }.always {
                self.hideLoading()
                if self.tableView.mj_header.isRefreshing() {
                    self.tableView.mj_header.endRefreshing()
                }
            }.catch { (myerror) in
                let customError = myerror as! OOAppError
                self.showError(title: customError.failureReason ?? "")
        }
    }
    
    @objc func selectSubmit(_ sender:Any) {
        guard let block = delegate else {
            return
        }
        var hasReIdle = false
        var hasClose = false
        if let room = self.selectedMeetingRooms.first {
            if room.idle == false {
                hasReIdle = true
            }
            if room.available == false {
                hasClose = true
            }
        }
        if hasReIdle {
            self.showError(title: "会议室已预约，请选择其它时间段")
            return
        }
        if hasClose {
            self.showError(title: "会议室已关闭，请选择其它会议室")
            return
        }
        block.backResult("OOMeetingMeetingRoomManageController", selectedMeetingRooms)
        self.popVC()
    }
    
    @objc func closeWindow() {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        //tableView.emptyDataSetSource = self
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showMeetingRoomInfoSegue"{
            let destVC = segue.destination as? OOMeetingRoomDetailViewController
            let item = sender as? OOMeetingRoomInfo
            destVC?.ooMeetingRoomInfo = item
        }
    }
    

}
// MARK:- HeaderViewDelegate
extension OOMeetingMeetingRoomManageController:OOMeetingRoomTableHeaderViewDelegate {
    func setTheDate(_ startDate: String, _ endDate: String) {
        loadAllBuildByDate(startDate, endDate)
    }
}

// MARK:- emptyDataSet
extension OOMeetingMeetingRoomManageController:EmptyDataSetSource,EmptyDataSetDelegate {
    
    func title(forEmptyDataSet scrollView: UIScrollView) -> NSAttributedString? {
        return NSAttributedString(string: "亲，您当前没有会议地点，请联系管理员！", attributes:[NSAttributedString.Key.foregroundColor:UIColor.init(hex: "#CCCCCC"),NSAttributedString.Key.font:UIFont.init(name: "PingFangSC-Light", size: 16)!])
    }
    
    func image(forEmptyDataSet scrollView: UIScrollView) -> UIImage? {
        return #imageLiteral(resourceName: "icon_huiyishi_nor")
    }
}


// MARK:- TableViewDataSource Delegate
extension OOMeetingMeetingRoomManageController:UITableViewDataSource,UITableViewDelegate {
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return viewModel.numberOfSections()
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.numberOfRowsInSection(section)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: reuseIdentifier, for: indexPath)
        let uCell = cell as! OOMeetingRoomMainCell
        let item = viewModel.nodeForIndexPath(indexPath)
        uCell.newConfig(withItem: item, showSelected: self.currentMode == 1)
        return cell
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        return viewModel.headerViewOfSection(section)
    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        return viewModel.footerViewOfSection(section)
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let item = viewModel.nodeForIndexPath(indexPath)
        if currentMode == 0 {
            self.performSegue(withIdentifier: "showMeetingRoomInfoSegue", sender: item)
        }else{
            self.selectedMeetingRooms.append(item!)
            self.selectedCellIndexPaths.append(indexPath)
            let cell = tableView.cellForRow(at: indexPath) as? OOMeetingRoomMainCell
            cell?.selectRoom(isSelected: true)
        }
    }
    
    
    func tableView(_ tableView: UITableView, didDeselectRowAt indexPath: IndexPath) {
        let item = viewModel.nodeForIndexPath(indexPath)
        if let index = self.selectedMeetingRooms.firstIndex(of: item!) {
            self.selectedMeetingRooms.remove(at: index)
            self.selectedCellIndexPaths.remove(at: selectedCellIndexPaths.firstIndex(of: indexPath)!)
        }
        let cell = tableView.cellForRow(at: indexPath) as? OOMeetingRoomMainCell
        cell?.selectRoom(isSelected: false)
    }
}
