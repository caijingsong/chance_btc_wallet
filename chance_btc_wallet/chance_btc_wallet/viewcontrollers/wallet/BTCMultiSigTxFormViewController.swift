//
//  BTCMultiSigTxFormViewController.swift
//  chance_btc_wallet
//
//  Created by Chance on 2017/3/16.
//  Copyright © 2017年 chance. All rights reserved.
//

import UIKit

class BTCMultiSigTxFormViewController: BaseViewController {

    @IBOutlet var buttonNext: UIButton!
    @IBOutlet var textViewContent: CHTextView!
    @IBOutlet var labelTips: UILabel!
    
    var currentAccount: CHBTCAcount! 
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupUI()
    }

    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    

    /*
    // MARK: - Navigation

    // In a storyboard-based application, you will often want to do a little preparation before navigation
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        // Get the new view controller using segue.destinationViewController.
        // Pass the selected object to the new view controller.
    }
    */

}

// MARK: - 控制器方法
extension BTCMultiSigTxFormViewController {
    
    /**
     配置UI
     */
    func setupUI() {
        
        self.navigationItem.title = "Sign Contract".localized()
        
        self.labelTips.text = "Paste the wallet Multi-Sig transaction protocol text.The prefix is \"multisig:\".".localized()
        self.textViewContent.placeHolder = "e.g: multisig:{\n\t\"rawTx\":\"...\",\n\t\"redeemScriptHex\":\"...\",\n\t\"keySignatures\":{…}\n}"
        self.buttonNext.setTitle("Next".localized(), for: .normal)
        
    }
    
    
    /// 检查输入值是否合法
    ///
    /// - Returns: 
    func checkValue() -> Bool {
        if self.textViewContent.text.isEmpty {
            SVProgressHUD.showInfo(withStatus: "Multi-Sig Transaction is empty".localized())
            
            return false
        }
        
        return true
    }
    
    
    /// 点击下一步
    ///
    /// - Parameter sender:
    @IBAction func handleNextPress(sender: AnyObject?) {
        //关闭键盘
        AppDelegate.sharedInstance().closeKeyBoard()
        
        guard self.checkValue() else {
            return
        }
        
        do {
            
            //封装一个多重签名交易表单
            let mtx = try MultiSigTransaction(json: self.textViewContent.text.trim())
            
            //检查是否钱包有可签名的账户
            guard let account = self.searchAccountToSign(mtx) else {
                SVProgressHUD.showError(withStatus: "Can not find account to sign!".localized())
                return
            }
            
            guard let vc = StoryBoard.wallet.initView(type: BTCMultiSigTransactionViewController.self) else {
                SVProgressHUD.showError(withStatus: "Unknown error".localized())
                return
            }
         
            vc.multiSigTx = mtx
            vc.currentAccount = account
            self.navigationController?.pushViewController(vc, animated: true)
        } catch {
            SVProgressHUD.showError(withStatus: "Transaction decode error".localized())
        }
        
        
    }
    
    /// 查找钱包中可以签名的账户
    ///
    /// - Returns: 返回是否找到账户?
    func searchAccountToSign(_ mtx: MultiSigTransaction) ->  CHBTCAcount? {
        
        guard let rs = mtx.redeemScriptHex.toBTCScript() else {
            return nil
        }
        
        guard let (publickeys, _) = rs.getMultisigPublicKeys() else {
            return nil
        }
        
        for publickey in publickeys {
            guard let account = CHBTCWallet.sharedInstance.getAccount(byPublickey: publickey) else {
                continue
            }
            return account
        }
        
        return nil
    }

}

// MARK: - 实现TextView委托方法
extension BTCMultiSigTxFormViewController: UITextViewDelegate {
    

    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            textView.resignFirstResponder()
            return false
        }
        return true
    }
    
}
