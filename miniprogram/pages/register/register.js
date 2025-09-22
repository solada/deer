// pages/register/register.js
const app = getApp()

Page({
  data: {
    username: '',
    email: '',
    nickname: '',
    password: '',
    confirmPassword: '',
    showPassword: false,
    showConfirmPassword: false,
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

  // 邮箱输入
  onEmailInput(e) {
    this.setData({
      email: e.detail.value
    })
    this.checkCanSubmit()
  },

  // 昵称输入
  onNicknameInput(e) {
    this.setData({
      nickname: e.detail.value
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

  // 确认密码输入
  onConfirmPasswordInput(e) {
    this.setData({
      confirmPassword: e.detail.value
    })
    this.checkCanSubmit()
  },

  // 切换密码显示/隐藏
  togglePassword() {
    this.setData({
      showPassword: !this.data.showPassword
    })
  },

  // 切换确认密码显示/隐藏
  toggleConfirmPassword() {
    this.setData({
      showConfirmPassword: !this.data.showConfirmPassword
    })
  },

  // 检查是否可以提交
  checkCanSubmit() {
    const { username, email, password, confirmPassword } = this.data
    const canSubmit = username.trim().length >= 3 && 
                     email.trim().length > 0 && 
                     password.trim().length >= 6 && 
                     confirmPassword.trim().length > 0
    this.setData({ canSubmit })
  },

  // 验证邮箱格式
  isValidEmail(email) {
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/
    return emailRegex.test(email)
  },

  // 处理注册
  async handleRegister() {
    if (!this.data.canSubmit || this.data.loading) return

    const { username, email, nickname, password, confirmPassword } = this.data

    // 验证用户名
    if (username.trim().length < 3 || username.trim().length > 20) {
      wx.showToast({
        title: '用户名长度为3-20个字符',
        icon: 'none'
      })
      return
    }

    // 验证邮箱
    if (!this.isValidEmail(email.trim())) {
      wx.showToast({
        title: '请输入有效的邮箱地址',
        icon: 'none'
      })
      return
    }

    // 验证密码
    if (password.trim().length < 6) {
      wx.showToast({
        title: '密码至少6个字符',
        icon: 'none'
      })
      return
    }

    // 验证确认密码
    if (password !== confirmPassword) {
      wx.showToast({
        title: '两次输入的密码不一致',
        icon: 'none'
      })
      return
    }

    this.setData({ loading: true })

    try {
      const res = await app.request({
        url: '/register',
        method: 'POST',
        data: {
          username: username.trim(),
          email: email.trim(),
          nickname: nickname.trim() || username.trim(),
          password: password.trim()
        }
      })

      // 保存登录信息
      app.login(res.user, res.token)

      wx.showToast({
        title: '注册成功',
        icon: 'success'
      })

      // 延迟跳转，让用户看到成功提示
      setTimeout(() => {
        wx.switchTab({
          url: '/pages/index/index'
        })
      }, 1500)

    } catch (error) {
      console.error('注册失败:', error)
      this.setData({ loading: false })
    }
  },

  // 跳转到登录页
  goToLogin() {
    wx.navigateBack()
  }
})
