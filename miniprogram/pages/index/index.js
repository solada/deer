// pages/index/index.js
const app = getApp()

Page({
  data: {
    posts: [],
    loading: false,
    hasMore: true,
    page: 1,
    limit: 10,
    isLoggedIn: false,
    userInfo: null
  },

  onLoad() {
    this.checkLoginStatus()
    this.loadPosts()
  },

  onShow() {
    this.checkLoginStatus()
    // 重新加载帖子列表（可能有新帖子或删除了帖子）
    this.refreshPosts()
  },

  onPullDownRefresh() {
    this.refreshPosts()
  },

  onReachBottom() {
    if (this.data.hasMore && !this.data.loading) {
      this.loadMorePosts()
    }
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

  // 加载帖子列表
  async loadPosts() {
    if (this.data.loading) return

    this.setData({ loading: true })

    try {
      const res = await app.request({
        url: '/posts',
        data: {
          page: this.data.page,
          limit: this.data.limit
        }
      })

      const posts = res.posts.map(post => ({
        ...post,
        formatted_time: app.formatTime(post.created_at)
      }))

      this.setData({
        posts: this.data.page === 1 ? posts : [...this.data.posts, ...posts],
        hasMore: res.pagination.current_page < res.pagination.total_pages,
        loading: false
      })

      if (this.data.page === 1) {
        wx.stopPullDownRefresh()
      }
    } catch (error) {
      console.error('加载帖子失败:', error)
      this.setData({ loading: false })
      wx.stopPullDownRefresh()
    }
  },

  // 刷新帖子列表
  refreshPosts() {
    this.setData({
      page: 1,
      hasMore: true,
      posts: []
    })
    this.loadPosts()
  },

  // 加载更多帖子
  loadMorePosts() {
    this.setData({
      page: this.data.page + 1
    })
    this.loadPosts()
  },

  // 跳转到帖子详情
  goToDetail(e) {
    const id = e.currentTarget.dataset.id
    wx.navigateTo({
      url: `/pages/post-detail/post-detail?id=${id}`
    })
  },

  // 跳转到登录页
  goToLogin() {
    wx.navigateTo({
      url: '/pages/login/login'
    })
  },

  // 跳转到发帖页
  goToPublish() {
    if (!this.data.isLoggedIn) {
      wx.showToast({
        title: '请先登录',
        icon: 'none'
      })
      return
    }
    
    wx.switchTab({
      url: '/pages/publish/publish'
    })
  },

  // 删除帖子
  deletePost(e) {
    e.stopPropagation() // 阻止冒泡到父元素的点击事件
    
    const id = e.currentTarget.dataset.id
    const title = e.currentTarget.dataset.title

    wx.showModal({
      title: '确认删除',
      content: `确定要删除帖子"${title}"吗？删除后无法恢复。`,
      confirmText: '删除',
      confirmColor: '#ff4757',
      success: (res) => {
        if (res.confirm) {
          this.performDelete(id)
        }
      }
    })
  },

  // 执行删除操作
  async performDelete(id) {
    wx.showLoading({
      title: '删除中...'
    })

    try {
      await app.request({
        url: `/posts/${id}`,
        method: 'DELETE'
      })

      wx.hideLoading()
      wx.showToast({
        title: '删除成功',
        icon: 'success'
      })

      // 从列表中移除已删除的帖子
      const posts = this.data.posts.filter(post => post.id !== id)
      this.setData({ posts })

    } catch (error) {
      wx.hideLoading()
      console.error('删除帖子失败:', error)
    }
  }
})
