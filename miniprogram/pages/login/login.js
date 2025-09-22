// pages/login/login.js
const app = getApp()

Page({
  data: {
    username: '',
    password: '',
    showPassword: false,
    loading: false,
    canSubmit: false
  },

  onLoad() {
    // 如果已经登录，跳转到首页
    if (app.isLoggedIn()) {
      wx.switchTab({
        url: '/pages/index/index'
      })
    }
  },

  // 用户名输入
  onUsernameInput(e) {
    this.setData({
      username: e.detail.value
    })
    this.checkCanSubmit()
  },

  // 密码输入
  onPasswordInput(e) {
    this.setData({
      password: e.detail.value
    })
    this.checkCanSubmit()
  },

  // 切换密码显示/隐藏
  togglePassword() {
    this.setData({
      showPassword: !this.data.showPassword
    })
  },

  // 检查是否可以提交
  checkCanSubmit() {
    const { username, password } = this.data
    const canSubmit = username.trim().length > 0 && password.trim().length > 0
    this.setData({ canSubmit })
  },

  // 处理登录
  async handleLogin() {
    if (!this.data.canSubmit || this.data.loading) return

    const { username, password } = this.data

    // 基本验证
    if (!username.trim()) {
      wx.showToast({
        title: '请输入用户名',
        icon: 'none'
      })
      return
    }

    if (!password.trim()) {
      wx.showToast({
        title: '请输入密码',
        icon: 'none'
      })
      return
    }

    this.setData({ loading: true })

    try {
      const res = await app.request({
        url: '/login',
        method: 'POST',
        data: {
          username: username.trim(),
          password: password.trim()
        }
      })

      // 保存登录信息
      app.login(res.user, res.token)

      wx.showToast({
        title: '登录成功',
        icon: 'success'
      })

      // 延迟跳转，让用户看到成功提示
      setTimeout(() => {
        wx.switchTab({
          url: '/pages/index/index'
        })
      }, 1500)

    } catch (error) {
      console.error('登录失败:', error)
      this.setData({ loading: false })
    }
  },

  // 跳转到注册页
  goToRegister() {
    wx.navigateTo({
      url: '/pages/register/register'
    })
  }
})
