// pages/profile/profile.js
const app = getApp()

Page({
  data: {
    isLoggedIn: false,
    userInfo: null
  },

  onLoad() {
    this.checkLoginStatus()
  },

  onShow() {
    this.checkLoginStatus()
  },

  // 检查登录状态
  checkLoginStatus() {
    const isLoggedIn = app.isLoggedIn()
    const userInfo = app.globalData.userInfo
    
    this.setData({
      isLoggedIn,
      userInfo
    })
  },

  // 跳转到我的帖子（暂时跳转到首页）
  goToMyPosts() {
    wx.showToast({
      title: '功能开发中',
      icon: 'none'
    })
    // TODO: 实现我的帖子页面
    // wx.navigateTo({
    //   url: '/pages/my-posts/my-posts'
    // })
  },

  // 刷新数据
  refreshData() {
    wx.showLoading({
      title: '刷新中...'
    })

    // 模拟刷新操作
    setTimeout(() => {
      wx.hideLoading()
      wx.showToast({
        title: '刷新完成',
        icon: 'success'
      })
      
      // 重新检查登录状态
      this.checkLoginStatus()
    }, 1000)
  },

  // 退出登录
  logout() {
    wx.showModal({
      title: '确认退出',
      content: '确定要退出登录吗？',
      confirmText: '退出',
      confirmColor: '#ff4757',
      success: (res) => {
        if (res.confirm) {
          // 清除登录状态
          app.logout()
          
          // 更新页面状态
          this.setData({
            isLoggedIn: false,
            userInfo: null
          })
          
          wx.showToast({
            title: '已退出登录',
            icon: 'success'
          })
        }
      }
    })
  },

  // 跳转到登录页
  goToLogin() {
    wx.navigateTo({
      url: '/pages/login/login'
    })
  },

  // 跳转到注册页
  goToRegister() {
    wx.navigateTo({
      url: '/pages/register/register'
    })
  }
})
