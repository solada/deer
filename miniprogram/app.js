// app.js
App({
  globalData: {
    userInfo: null,
    token: null,
    baseUrl: 'https://deerlulu1008.cn/api'
  },

  onLaunch() {
    // 检查登录状态
    this.checkLogin()
  },

  // 检查登录状态
  checkLogin() {
    const token = wx.getStorageSync('token')
    const userInfo = wx.getStorageSync('userInfo')
    
    if (token && userInfo) {
      this.globalData.token = token
      this.globalData.userInfo = userInfo
    }
  },

  // 登录
  login(userInfo, token) {
    this.globalData.userInfo = userInfo
    this.globalData.token = token
    
    wx.setStorageSync('userInfo', userInfo)
    wx.setStorageSync('token', token)
  },

  // 登出
  logout() {
    this.globalData.userInfo = null
    this.globalData.token = null
    
    wx.removeStorageSync('userInfo')
    wx.removeStorageSync('token')
  },

  // 检查是否已登录
  isLoggedIn() {
    return !!(this.globalData.token && this.globalData.userInfo)
  },

  // 通用请求方法
  request(options) {
    const app = this
    
    return new Promise((resolve, reject) => {
      const header = {
        'Content-Type': 'application/json'
      }
      
      // 如果已登录，添加 Authorization 头
      if (app.globalData.token) {
        header.Authorization = `Bearer ${app.globalData.token}`
      }
      
      wx.request({
        url: `${app.globalData.baseUrl}${options.url}`,
        method: options.method || 'GET',
        data: options.data || {},
        header: header,
        success: (res) => {
          console.log('请求响应:', {
            url: `${app.globalData.baseUrl}${options.url}`,
            statusCode: res.statusCode,
            data: res.data
          })
          
          if (res.statusCode === 200 || res.statusCode === 201) {
            resolve(res.data)
          } else if (res.statusCode === 401) {
            // Token 过期，清除登录状态
            app.logout()
            wx.showToast({
              title: '登录已过期，请重新登录',
              icon: 'none'
            })
            setTimeout(() => {
              wx.navigateTo({
                url: '/pages/login/login'
              })
            }, 1500)
            reject(res.data)
          } else {
            const errorMsg = (res.data && res.data.error) || '请求失败'
            wx.showToast({
              title: errorMsg,
              icon: 'none'
            })
            reject(res.data || { error: errorMsg })
          }
        },
        fail: (err) => {
          wx.showToast({
            title: '网络错误',
            icon: 'none'
          })
          reject(err)
        }
      })
    })
  },

  // 格式化时间
  formatTime(dateString) {
    const date = new Date(dateString)
    const now = new Date()
    const diff = now - date
    
    // 小于1分钟
    if (diff < 60000) {
      return '刚刚'
    }
    
    // 小于1小时
    if (diff < 3600000) {
      return `${Math.floor(diff / 60000)}分钟前`
    }
    
    // 小于1天
    if (diff < 86400000) {
      return `${Math.floor(diff / 3600000)}小时前`
    }
    
    // 小于7天
    if (diff < 604800000) {
      return `${Math.floor(diff / 86400000)}天前`
    }
    
    // 格式化为日期
    const year = date.getFullYear()
    const month = String(date.getMonth() + 1).padStart(2, '0')
    const day = String(date.getDate()).padStart(2, '0')
    
    if (year === now.getFullYear()) {
      return `${month}-${day}`
    } else {
      return `${year}-${month}-${day}`
    }
  }
})
