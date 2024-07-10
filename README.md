
<div align="center">
  <img src="https://github.com/geon314159/Madcamp_Week_2/assets/69643543/ff1892dc-83a1-496b-9349-be9f859e0b13" alt="Login" width="200">
</div>

# GMS(Group Management System)를 소개합니다

여러 카톡방에 흩어져 있는 공지가 찾기 힘드시다구요?

일정을 정해야 하는데 when2meet을 기록하지 않는 팀원이 있어 일정을 정할 수 없다구요?

당신의 현명한 단체생활을 위한 단체 관리 어플이 여기 있습니다!
<br>

## Team


- [조영서](https://www.notion.so/9c9e5bc511ff4fb2bd9f317a13ce13a0?pvs=21) - Frontend
  - [cyshello - Overview](https://github.com/cyshello)

- [강건](https://www.notion.so/a9f5fe76226a458b976db96edcffcf20?pvs=21) - Backend
  - [geon314159 - Overview](https://github.com/geon314159)

<br>

## Tech Stack



- **Frontend**: Flutter
- **Backend**: Flask + MySQL
<br>


## Details


### 1. Login

- 처음 들어가면 상단에 로고가 있는 로그인 화면이 나타납니다.
- 기존 사용자라면 이메일과 비밀번호를 입력하여 들어갈 수 있고, 새로운 사용자는 기본 회원 가입을 사용하거나 카카오 계정을 활용하여 계정을 만들 수 있습니다.

<div align="center">
  <img src="https://github.com/geon314159/Madcamp_Week_2/assets/69643543/978663ef-a74a-49a0-9608-9509f127ce3e" alt="Login" width="500">
</div>

<br>
<br>

### 2. Main Screen & User Profile

- Main Screen에서는 본인의 간단한 프로필 정보를 위에서 볼 수 있고, 하단의 탭에서는 그룹을 만들거나 참여할 수 있습니다.
- 본인이 추가되어있는 그룹은 이름, 설명, 참여자 수의 정보를 메인 화면에서 확인할 수 있고, 해당 그룹에서 본인의 권한에 따라 리더, 멤버로 표시됩니다.
- 하단의 화면을 끌어올리면 그룹을 만들거나 참여할 수 있는 버튼이 나타납니다. 그룹을 처음 만들면 만든 사람에게 초대 코드가 주어지고, 해당 초대 코드를 다른 사람이 입력하면 그룹에 참여할 수 있습니다.
- 프로필을 누르면 상세 프로필 페이지로 이동하며, 유저의 이메일과 프로필 사진, 시간표 정보를 확인할 수 있으며, 각각 수정 또한 가능합니다.

<div align="center">
  <img src="https://github.com/geon314159/Madcamp_Week_2/assets/69643543/dee8ccd0-3f62-4a30-992a-30eb88c2c91e" alt="Login" width="500">
</div>

<br>
<br>


### 3. Group Page

#### 1) Main

- 그룹 페이지에서는 해당 그룹의 리더인 경우, 공지글, 미팅, 팀 추가/수정/삭제 등의 기능이 가능합니다.
- 우측 하단의 버튼을 눌러 원하는 동작을 선택할 수 있습니다.
- 게시글에서는 사진을 포함하여 작성할 수 있으며, 원하는 태그를 선택하여 업로드가 가능합니다.
- 미팅을 만들기를 시작하면, 먼저 필요한 시간 정보와 참여할 유저들의 목록을 받습니다. 이후 해당 유저들의 시간표 정보를 수합하여, 전체 인원이 가능한 시간 목록을 확인하여 미팅 시간을 확정할 수 있습니다.
- 미팅이 생성되면, 해당 정보를 기반으로 공지글이 작성됩니다.

<div align="center">
  <img src="https://github.com/geon314159/Madcamp_Week_2/assets/69643543/15b4b81b-1c44-4208-bba2-660d179c3b44" alt="Login" width="500">
</div>

<br>
<br>


#### 2) Tag

- 게시글의 경우 태그를 통한 필터링으로, 원하는 태그의 게시글을 확인할 수 있습니다.
- 태그의 수정이 가능하며, 이름과 색상을 선택하여 원하는 태그를 새롭게 커스터마이즈 할 수 있습니다.

<div align="center">
  <img src="https://github.com/geon314159/Madcamp_Week_2/assets/69643543/7a6450e6-fc23-49e6-8647-bdb12a5e7ca6" alt="Login" width="500">
</div>

<br>
<br>

#### 3) Schedule

- 하단의 스케줄 네비게이션 바로 들어가면 캘린더가 나타납니다.
- 해당 그룹에서 생성된 미팅들을 확인할 수 있으며, 수정도 가능합니다.

<div align="center">
  <img src="https://github.com/geon314159/Madcamp_Week_2/assets/69643543/8a10fecd-ec06-4cba-9092-81d7ca4039bc" alt="Login" width="500">
</div>

<br>
<br>


### 4. Team Page

- 그룹 페이지에서 하단의 팀 네비게이션 바로 들어가면, 그룹에 소속된 팀 화면이 나타납니다.
- 해당 그룹에서 생성된 팀들을 확인할 수 있으며, 참여중인 팀 멤버 수도 확인할 수 있습니다.
- 해당 팀의 리더 프로필을 확인할 수 있고, 본인이 리더일 경우 리더 표시를 확인할 수 있습니다.
- 팀을 누르면 팀 상세 페이지로 이동하며, 기능은 그룹 페이지와 동일합니다.
- 이때 태그는 팀이 소속된 그룹의 태그를 그대로 사용할 수 있습니다.

<div align="center">
  <img src="https://github.com/geon314159/Madcamp_Week_2/assets/69643543/1d24ab16-1059-4d42-8274-390a951eec7d" alt="Login" width="500">
</div>

<br>
<br>


## DB Design


- 전반적인 디자인은 아래 diagram 참고 부탁드립니다.

[DB Design Link](https://dbdiagram.io/d/668d07c79939893dae6ee38a)

<div align="center">
  <img src="https://github.com/geon314159/Madcamp_Week_2/assets/69643543/16b8914d-03fd-43f6-b29d-877e338ae0ca" alt="Login" width="500">
</div>

<br>
<br>

## APK File
- TBD
