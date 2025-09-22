// pages/publish/publish.js
const app = getApp()

Page({
  data: {
    title: '',
    content: '',
    publishing: false,
    canPublish: false,
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

  // 标题输入
  onTitleInput(e) {
    this.setData({
      title: e.detail.value
    })
    this.checkCanPublish()
  },

  // 内容输入
  onContentInput(e) {
    this.setData({
      content: e.detail.value
    })
    this.checkCanPublish()
  },

  // 检查是否可以发布
  checkCanPublish() {
    const { title, content } = this.data
    const canPublish = title.trim().length > 0 && content.trim().length > 0
    this.setData({ canPublish })
  },

  // 发布帖子
  async publishPost() {
    if (!this.data.isLoggedIn) {
      wx.showToast({
        title: '请先登录',
        icon: 'none'
      })
      return
    }

    if (!this.data.canPublish || this.data.publishing) return

    const { title, content } = this.data

    // 验证标题
    if (!title.trim()) {
      wx.showToast({
        title: '请输入帖子标题',
        icon: 'none'
      })
      return
    }

    if (title.trim().length > 200) {
      wx.showToast({
        title: '标题不能超过200个字符',
        icon: 'none'
      })
      return
    }

    // 验证内容
    if (!content.trim()) {
      wx.showToast({
        title: '请输入帖子内容',
        icon: 'none'
      })
      return
    }

    if (content.trim().length > 10000) {
      wx.showToast({
        title: '内容不能超过10000个字符',
        icon: 'none'
      })
      return
    }

    this.setData({ publishing: true })

    try {
      const res = await app.request({
        url: '/posts',
        method: 'POST',
        data: {
          title: title.trim(),
          content: content.trim()
        }
      })

      wx.showToast({
        title: '发布成功',
        icon: 'success'
      })

      // 清空表单
      this.setData({
        title: '',
        content: '',
        publishing: false,
        canPublish: false
      })

      // 延迟跳转到帖子详情页
      setTimeout(() => {
        wx.navigateTo({
          url: `/pages/post-detail/post-detail?id=${res.post.id}`
        })
      }, 1500)

    } catch (error) {
      console.error('发布帖子失败:', error)
      this.setData({ publishing: false })
    }
  },

  // 清空表单
  clearForm() {
    wx.showModal({
      title: '确认清空',
      content: '确定要清空所有内容吗？',
      success: (res) => {
        if (res.confirm) {
          this.setData({
            title: '',
            content: '',
            canPublish: false
          })
          wx.showToast({
            title: '已清空',
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
  }
})
